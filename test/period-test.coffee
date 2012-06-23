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


logErrorResponse = (model,response) ->
  console.log "response: #{require('util').inspect response}"


exports.testGetDailyPeriod =

  setUp: (callback) ->
    @leagueStatsKey = "dsjhksajdhkajshkj"
    @league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    @league.save @league.toJSON(),
      error: logErrorResponse
      success: (model,response) =>
        @periodData = 
          leagueId: @league.id
          startDate: new Date("Jan 1, 2010")
          endDate: new Date("Jan 2, 2010")
        @periodData.id = Period.getCouchId
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          date: @periodData.startDate
        p = new Period @periodData
        p.save p.toJSON(),
          error: -> console.log "error saving Period"
          success: (model,response) =>
            @period = model
            callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: logErrorResponse
      success: => 
        @league.destroy
          error: logErrorResponse
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
      test.ok periodData.league
      test.equal periodData.leagueId,@league.id,"@league.id"
      test.equal periodData.category,@period.get("basePeriodCategory")
      test.equal periodData.startDate, @periodData.startDate.toJSON()
      test.equal periodData.endDate, @periodData.endDate.toJSON()
      test.done()


exports.testFetchAssociatedModels = 

  setUp: (callback) ->
    @leagueStatsKey = "oe82gqn8uwxgn"
    @league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    @league.save @league.toJSON(),
      error: logErrorResponse
      success: (model,response) =>
        @periodData = 
          leagueId: @league.id
          startDate: new Date("Jan 11, 2010")
          endDate: new Date("Jan 12, 2010")
        @periodData.id = Period.getCouchId
          category: @league.get("basePeriodCategory")
          date: @periodData.startDate
          leagueId: @league.id
        p = new Period(@periodData)
        p.save p.toJSON(),
          error: -> logErrorResponse
          success: (model,response) =>
            @period = model
            callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: -> logErrorResponse
      success: => 
        @league.destroy
          error: -> logErrorResponse
          success: -> callback()

  testFetchGames: (test) ->
    test.ok @period
    @period.fetchGames
      error: logErrorResponse
      success: (games,response) =>
        test.equal games.length,0
        g1 = new Game
          leagueId: @league.id
          startDate: (new Date(@periodData.startDate)).addHours(1)
        g1.save g1.toJSON(),
          error: logErrorResponse
          success: (game1,response) =>
            test.ok game1
            test.ok game1.id
            @period.fetchGames
              error: logErrorResponse
              success: (games,response) =>
                test.equal games.length,1
                test.equal games[0].id, game1.id
                g2 = new Game
                  leagueId: @league.id
                  startDate: new Date(2010,1,16,17,00)
                g2.save g2.toJSON(),
                  error: logErrorResponse
                  success: (game2,response) =>
                    test.ok game2
                    @period.fetchGames
                      error: logErrorResponse
                      success: (games,response) =>
                        test.equal games.length,1,"should be 1 game only"
                        test.equal games[0].id,game1.id,"should be 1st game"
                        game2.destroy
                          error: logErrorResponse
                          success: =>
                            test.done()
                            game1.destroy
                              error: logErrorResponse
                              success: =>
                                test.done()

  testFetchUserPeriods: (test) ->
    test.ok @period
    @period.fetchUserPeriods
      error: logErrorResponse
      success: (userPeriods,response) =>
        test.equal userPeriods.length,0
        user = new User()
        user.save user.toJSON(),
          error: logErrorResponse
          success: (user,response) =>
            UserPeriod.createForUserAndPeriod {userId:user.id,periodId:@period.id},
              error: logErrorResponse
              success: (userPeriod,response) =>
                test.ok userPeriod
                test.ok userPeriod.id
                test.equal userPeriod.get("periodId"), @period.id
                @period.fetchUserPeriods
                  error: logErrorResponse
                  success: (userPeriods,response) =>
                    test.equal userPeriods.length, 1
                    test.equal userPeriods[0].get("id"),userPeriod.id
                    user2 = new User()
                    user2.save user2.toJSON(),
                      error: logErrorResponse
                      success: (user2,response) =>
                        UserPeriod.createForUserAndPeriod {userId:user2.id,periodId:@period.id},
                          error: logErrorResponse
                          success: (userPeriod2,response) =>
                            test.ok userPeriod2
                            @period.fetchUserPeriods
                              error: logErrorResponse
                              success: (userPeriods,response) =>
                                test.equal userPeriods.length, 2
                                userPeriod.destroy
                                  error: logErrorResponse
                                  success: =>
                                    userPeriod2.destroy
                                      error: logErrorResponse
                                      success: =>
                                        user.destroy
                                          error: logErrorResponse
                                          success: => 
                                            user2.destroy
                                              error: logErrorResponse
                                              success: => test.done()