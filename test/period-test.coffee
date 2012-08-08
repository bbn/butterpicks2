util = require "util"

journey = require "journey"
controllers = require "../lib/controllers"
mockRequest = require "../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
journey.env = "test"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

Period = models.Period
User = models.User
UserPeriod = models.UserPeriod
Game = models.Game
League = models.League

require "../lib/date"


logErrorResponse = (message) ->
  (model,response) ->
    console.log "#{message} -> response: #{require('util').inspect response}"


exports.testGetDailyPeriod =

  setUp: (callback) ->
    @leagueStatsKey = "dsjhksajdhkajshkj"
    @league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    @league.save @league.toJSON(),
      error: logErrorResponse "@league.save"
      success: (model,response) =>
        @periodData = 
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          startDate: new Date("Jan 1, 2010")
          endDate: new Date("Jan 2, 2010")
        p = new Period @periodData
        p.save p.toJSON(),
          error: logErrorResponse "p.save"
          success: (model,response) =>
            @period = model
            callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: logErrorResponse "@period.destroy"
      success: => 
        @league.destroy
          error: logErrorResponse "@league.destroy"
          success: -> callback()

  testGetDailyPeriod: (test) ->
    test.ok @period, "cached model is ok"
    test.ok @league.id
    d = @periodData.startDate
    dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
    url = "/period?category=#{@league.get("basePeriodCategory")}&leagueId=#{@league.id}&date=#{dateString}"
    x = mock.get url, { accept: "application/json" }
    x.on "success", (response) =>
      test.ok response, "response is ok"
      test.equal response.body.error,null,"error should be null: #{util.inspect response.body.error}"
      test.equal response.status, 200, "status should be 200"
      test.ok response.body
      periodData = response.body
      test.equal periodData.id, @period.id,"@period.id"
      test.equal periodData.leagueId,@league.id,"@league.id"
      test.equal periodData.category,@period.get("category")
      test.equal periodData.startDate, @periodData.startDate.toJSON()
      test.equal periodData.endDate, @periodData.endDate.toJSON()
      test.done()


exports.testGetOrCreateBasePeriodForGame = (test) ->
  league = new League
    statsKey: "27eqiugwdasb"
    basePeriodCategory: "daily"
  league.save league.toJSON(),
    error: logErrorResponse "league.save"
    success: (model,response) ->
      game = new Game
        leagueId: league.id
        startDate: new Date(2011,0,1,13,30)
        statsKey: "o7gfhbdjfso87qrgaf"
      game.save game.toJSON(),
        error: logErrorResponse "game.save"
        success: (game) ->
          Period.getOrCreateBasePeriodForGame game,
            error: logErrorResponse "Period.getOrCreateBasePeriodForGame"
            success: (period) ->
              test.ok period
              test.ok period.id
              test.equal period.get("leagueId"), game.get("leagueId")
              test.equal period.get("startDate").toJSON(), (new Date(2011,0,1)).toJSON()
              period.destroy
                success: -> game.destroy
                  success: -> league.destroy
                    success: -> test.done()




exports.testFetchAssociatedModels = 

  setUp: (callback) ->
    @leagueStatsKey = "oe82gqn8uwxgn"
    @league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    @league.save @league.toJSON(),
      error: logErrorResponse "@league.save"
      success: (model,response) =>
        @periodData = 
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          startDate: new Date("Jan 11, 2010")
          endDate: new Date("Jan 12, 2010")
        p = new Period(@periodData)
        p.save p.toJSON(),
          error: -> logErrorResponse "p.save"
          success: (model,response) =>
            @period = model
            callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: -> logErrorResponse "@period.destroy"
      success: => 
        @league.destroy
          error: -> logErrorResponse "@league.destroy"
          success: -> callback()

  testFetchGames: (test) ->
    test.ok @period
    @period.fetchGames
      error: logErrorResponse "@period.fetchGames"
      success: (games,response) =>
        test.equal games.length,0
        g1 = new Game
          leagueId: @league.id
          startDate: (new Date(@periodData.startDate)).addHours(1)
          statsKey: "872roqfgjhbs7uiljks"
        g1.save g1.toJSON(),
          error: logErrorResponse "g1.save"
          success: (game1,response) =>
            test.ok game1
            test.ok game1.id
            @period.games = null
            @period.fetchGames
              error: logErrorResponse "@period.fetchGames"
              success: (games,response) =>
                test.equal games.length,1
                test.equal games[0].id, game1.id
                g2 = new Game
                  leagueId: @league.id
                  startDate: new Date(2010,1,16,17,00)
                  statsKey: "7uihqlwfjslsalkjas"
                g2.save g2.toJSON(),
                  error: logErrorResponse "g2.save"
                  success: (game2,response) =>
                    test.ok game2
                    @period.games = null
                    @period.fetchGames
                      error: logErrorResponse "@period.fetchGames"
                      success: (games,response) =>
                        test.equal games.length,1,"should be 1 game only"
                        test.equal games[0].id,game1.id,"should be 1st game"
                        game2.destroy
                          error: logErrorResponse "game2.destroy"
                          success: =>
                            test.done()
                            game1.destroy
                              error: logErrorResponse "game1.destroy"
                              success: =>
                                test.done()

  testFetchUserPeriods: (test) ->
    test.ok @period
    @period.fetchUserPeriods
      error: logErrorResponse "@period.fetchUserPeriods"
      success: (userPeriods,response) =>
        test.equal userPeriods.length,0
        user = new User()
        user.save user.toJSON(),
          error: logErrorResponse "user.save"
          success: (user,response) =>
            UserPeriod.createForUserAndPeriod {userId:user.id,periodId:@period.id},
              error: logErrorResponse "UserPeriod.createForUserAndPeriod"
              success: (userPeriod,response) =>
                test.ok userPeriod
                test.ok userPeriod.id
                test.equal userPeriod.get("periodId"), @period.id
                @period.fetchUserPeriods
                  error: logErrorResponse "@period.fetchUserPeriods"
                  success: (userPeriods,response) =>
                    test.equal userPeriods.length, 1
                    test.equal userPeriods[0].get("id"),userPeriod.id
                    user2 = new User()
                    user2.save user2.toJSON(),
                      error: logErrorResponse "user2.save"
                      success: (user2,response) =>
                        UserPeriod.createForUserAndPeriod {userId:user2.id,periodId:@period.id},
                          error: logErrorResponse "UserPeriod.createForUserAndPeriod"
                          success: (userPeriod2,response) =>
                            test.ok userPeriod2
                            @period.fetchUserPeriods
                              error: logErrorResponse "@period.fetchUserPeriods"
                              success: (userPeriods,response) =>
                                test.equal userPeriods.length, 2
                                userPeriod.destroy
                                  error: logErrorResponse "userPeriod.destroy"
                                  success: =>
                                    userPeriod2.destroy
                                      error: logErrorResponse "userPeriod2.destroy"
                                      success: =>
                                        user.destroy
                                          error: logErrorResponse "user.destroy"
                                          success: => 
                                            user2.destroy
                                              error: logErrorResponse "user2.destroy"
                                              success: => test.done()


exports.testPeriodFinal = (test) ->
  leagueId = "fghdak28oihdaskjbakdh"
  period = new Period
    leagueId: leagueId
    category: "daily"
    startDate: new Date(2011,0,1)
    endDate: new Date(2011,0,2)
  period.save period.toJSON(),
    error: logErrorResponse "period.save"
    success: (period) ->
      game1 = new Game
        leagueId: leagueId
        startDate: new Date(2011,0,1,12)
        statsKey: "daskjds8ayuhkj"
        status:
          final: false
      game1.save game1.toJSON(),
        error: logErrorResponse "game1.save"
        success: (game1) ->
          game2 = new Game
            statsKey: "sakjhsaduysailugd"
            leagueId: leagueId
            startDate: new Date(2011,0,1,11)
            status:
              final: true
          game2.save game2.toJSON(),
            error: logErrorResponse "game2.save"
            success: (game2) ->
              period.fetchMetrics
                error: logErrorResponse "period.fetchMetrics"
                success: (metrics) ->
                  test.equal metrics.games, 2
                  test.equal metrics.allGamesFinal, false
                  game1.save {status:{final:true}},
                    error: logErrorResponse "game1.save 2"
                    success: (game1) ->
                      period.games = null
                      period.fetchMetrics
                        error: logErrorResponse "period.fetchMetrics 2"
                        success: (metrics) ->
                          test.equal metrics.games, 2
                          test.equal metrics.allGamesFinal, true
                          game2.destroy
                            success: -> game1.destroy
                              success: -> period.destroy
                                success: ->
                                  test.done()
