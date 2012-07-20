util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

User = models.User
League = models.League
Period = models.Period
UserPeriod = models.UserPeriod
Game = models.Game
Pick = models.Pick


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createUserPeriod = 
  
  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @leagueStatsKey = "6rciytexutsdulblu7"
        @league = new League
          statsKey: @leagueStatsKey
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: (league,response) =>
            @periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Jan 11, 2012")
              endDate: new Date("Jan 12, 2012")
            @periodData.id = Period.getCouchId
              category: @league.get("basePeriodCategory")
              date: @periodData.startDate
              leagueStatsKey: @league.get("statsKey")
            @period = new Period(@periodData)
            @period.save @period.toJSON(),
              error: -> logErrorResponse "saving period"
              success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @period.destroy
          error: logErrorResponse "destroying period"
          success: => 
            @league.destroy
              error: logErrorResponse "@league.destroy"
              success: =>
                callback()

  testCreateUserPeriod: (test) ->
    test.ok @user.id
    test.ok @period.id
    test.ok @league.id
    params = 
      userId: @user.id
      periodId: @period.id
    UserPeriod.createForUserAndPeriod params,
      error: logErrorResponse "UserPeriod.createForUserAndPeriod"
      success: (userPeriod,response) =>
        test.ok userPeriod
        test.ok userPeriod.id
        test.equal userPeriod.get("doctype"), "UserPeriod"
        test.equal userPeriod.get("userId"), @user.id
        test.equal userPeriod.get("periodId"), @period.id
        test.equal userPeriod.get("leagueId"), @league.id
        test.equal userPeriod.get("periodStartDate").toJSON(), @period.get("startDate").toJSON()
        test.equal userPeriod.get("periodCategory"), @period.get("category")
        userPeriod.destroy
          error: logErrorResponse "destroying userPeriod"
          success: -> test.done()



exports.testFetchUserPeriod = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @league = new League
          statsKey: @leagueStatsKey
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: (league,response) =>
            @periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Jan 11, 2012")
              endDate: new Date("Jan 12, 2012")
            @periodData.id = Period.getCouchId
              category: @league.get("basePeriodCategory")
              date: @periodData.startDate
              leagueStatsKey: @league.get("statsKey")
            @period = new Period(@periodData)
            @period.save @period.toJSON(),
              error: -> logErrorResponse "saving period"
              success: => 
                params = 
                  userId: @user.id
                  periodId: @period.id
                UserPeriod.createForUserAndPeriod params,
                  error: logErrorResponse "UserPeriod.createForUserAndPeriod"
                  success: (userPeriod,response) =>
                    @userPeriod = userPeriod
                    callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @period.destroy
          error: logErrorResponse "destroying period"
          success: => 
            @userPeriod.destroy
              error: logErrorResponse "destroying userPeriod"
              success: => 
                @league.destroy
                  error: logErrorResponse "@league.destroy"
                  success: => callback()

  testFetchUserPeriod: (test) ->
    test.ok @user.id
    test.ok @league.id
    test.ok @period.id
    test.ok @userPeriod.id
    params = 
      userId: @user.id
      periodId: @period.id
    UserPeriod.fetchForUserAndPeriod params,
      error: logErrorResponse "UserPeriod.fetchForUserAndPeriod"
      success: (userPeriod,response) =>
        test.ok userPeriod
        test.equal userPeriod.id, @userPeriod.id
        test.equal userPeriod.get("userId"), @user.id
        test.equal userPeriod.get("periodId"), @period.id
        test.equal userPeriod.get("leagueId"), @period.get("leagueId")
        test.equal userPeriod.get("periodStartDate").toJSON(), @period.get("startDate").toJSON()
        test.equal userPeriod.get("periodCategory"), @period.get("category")
        test.done()


exports.testFetchPicks = 

  setUp: (callback) ->
    @league = new League
      statsKey: "sadkjhskjahdsA"
      basePeriodCategory: "daiy"
    @league.save @league.toJSON(),
      success: =>
        @periodData = 
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          startDate: new Date("Mar 11, 2012")
          endDate: new Date("Mar 12, 2012")
        @periodData.id = Period.getCouchId
          category: @league.get("basePeriodCategory")
          date: @periodData.startDate
          leagueStatsKey: @league.get("statsKey")
        @period = new Period(@periodData)
        @period.save @period.toJSON(),
          success: =>
            @user = new User
            @user.save @user.toJSON(),
              success: =>
                UserPeriod.createForUserAndPeriod {userId:@user.id,periodId:@period.id},
                  success: (userPeriod) =>
                    @userPeriod = userPeriod
                    @game1 = new Game
                      statsKey: "khjgkjgb87o"
                      leagueId: @league.id
                      awayTeam:
                        statsKey: "oinli2uh3xq"
                      homeTeam:
                        statsKey: "akwhxo89i2uhkjwx"
                      startDate: @period.get("startDate").add({hours:1})
                      status:
                        score:
                          away: 1
                          home: 0
                        text: "final"
                        final: true
                      pickCount:
                        home: 100
                        away: 50
                        draw: 0
                    @game1.save @game1.toJSON(),
                      success: =>
                        @game2 = new Game
                          statsKey: "p298qywihkjacs"
                          leagueId: @league.id
                          awayTeam:
                            statsKey: "2qgwjbs"
                          homeTeam:
                            statsKey: "cnbq27iwugjbs"
                          startDate: @period.get("startDate").add({hours:3})
                          status:
                            score:
                              away: 2
                              home: 4
                            text: "final"
                            final: true
                          pickCount:
                            home: 80
                            away: 27
                            draw: 0
                        @game2.save @game2.toJSON(),
                          success: =>  
                            pickParams = 
                              userId: @user.id
                              gameId: @game1.id
                              home: true
                              away: false
                              draw: false
                              butter: false
                              createdDate: @game1.get("startDate").add({hours:-1})
                              updatedDate: @game1.get("startDate").add({hours:-1})
                            Pick.create pickParams,
                              success: (pick1) =>
                                @pick1 = pick1
                                pickParams.gameId = @game2.id
                                pickParams.home = false
                                pickParams.away = true                  
                                Pick.create pickParams,
                                  success: (pick2) =>
                                    @pick2 = pick2
                                    callback()

  tearDown: (callback) ->
    @pick2.destroy
      success: => @pick1.destroy
        success: => @game2.destroy
          success: => @game1.destroy
            success: => @userPeriod.destroy
              success: => @user.destroy
                success: => @period.destroy
                  success: => @league.destroy
                    success: => callback()

  testFetchPicks: (test) ->
    test.ok @league.id
    test.ok @period.id
    test.ok @user.id
    test.ok @userPeriod.id
    test.ok @game1.id
    test.ok @game2.id
    test.ok @pick1.id
    test.ok @pick2.id
    @userPeriod.games = [@game1,@game2]
    @userPeriod.fetchPicks
      error: logErrorResponse "@userPeriod.fetchPicks"
      success: (picks) =>
        test.equal picks.length, 2
        for pick in picks
          test.ok pick.game
        test.done()


exports.testDeterminePrizes = 

  setUp: (callback) -> 
    @league = new League
      statsKey: "21oxy8iluhdkjashk"
      basePeriodCategory: "daiy"
    @league.save @league.toJSON(),
      success: =>
        @periodData = 
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          startDate: new Date("Mar 21, 2012")
          endDate: new Date("Mar 22, 2012")
        @periodData.id = Period.getCouchId
          category: @league.get("basePeriodCategory")
          date: @periodData.startDate
          leagueStatsKey: @league.get("statsKey")
        @period = new Period(@periodData)
        @period.save @period.toJSON(),
          success: =>
            @user = new User
            @user.save @user.toJSON(),
              success: =>
                UserPeriod.createForUserAndPeriod {userId:@user.id,periodId:@period.id},
                  success: (userPeriod) =>
                    @userPeriod = userPeriod
                    callback()
  
  tearDown: (callback) -> 
    console.log "FIXME - delete all models"
    callback()

  testDeterminePrizes: (test) ->
    test.ok @user, "@user is defined"
    test.ok @period, "@period is defined"
    test.ok @userPeriod, "@userPeriod is defined"
    test.ok @prizeThatShouldBeAbleToWin
    test.ok @prizeWithoutPrerequisite
    test.ok @prizeThatRequiresMoreGames
    @userPeriod.determinePrizes
      error: logErrorResponse "@userPeriod.determinePrizes"
      success: (prizes) =>
        # test.equal prizes.length,1
        # test.equal prizes[0].id, @prizeThatShouldBeAbleToWin.id
        test.ok false, "implement testDeterminePrizes"
        test.done()

