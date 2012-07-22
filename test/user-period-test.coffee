util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"

User = models.User
League = models.League
Period = models.Period
UserPeriod = models.UserPeriod
Game = models.Game
Pick = models.Pick
Prize = models.Prize


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
                            Pick.create
                              userId: @user.id
                              gameId: @game1.id
                              home: true
                              away: false
                              draw: false
                              butter: false
                              createdDate: @game1.get("startDate").add({hours:-1})
                              updatedDate: @game1.get("startDate").add({hours:-1})
                              success: (pick1) =>
                                @pick1 = pick1
                                Pick.create
                                  userId: @user.id
                                  gameId: @game2.id
                                  home: false
                                  away: true
                                  draw: false
                                  butter: false
                                  createdDate: @game1.get("startDate").add({hours:-1})
                                  updatedDate: @game1.get("startDate").add({hours:-1})
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
                    @game = new Game
                      statsKey: "gdfashjkl6yu21o3fyuhbjd"
                      leagueId: @league.id
                      awayTeam:
                        statsKey: "d12itefbdygquwnilhals"
                        location: "Las Vegas"
                        name: "Dice"
                      homeTeam:
                        statsKey: "asdhasjkhdgkjahsgd"
                        location: "Utah"
                        name: "Sensibles"
                      startDate: new Date("19:00 Mar 21, 2012")
                      status:
                        score:
                          away: 12
                          home: 3
                        text: "final"
                        final: true
                      couldDraw: false 
                      legit: true
                      pickCount:
                        home: 100
                        away: 200
                        draw: 0
                    @game.save @game.toJSON(),
                      error: logErrorResponse "@game.save"
                      success: (game) =>
                        Pick.create
                          userId: @user.id
                          gameId: @game.id
                          away:true
                          home:false
                          draw:false
                          error: logErrorResponse "Pick.create"
                          success: (pick) =>
                            @pick = pick
                            @prizeThatShouldBeAbleToWin = new Prize
                              leagueId: @league.id
                              name: "prizeThatShouldBeAbleToWin"
                              description: "one correct pick"
                              pointValue: 10
                              eligibleConditions: [{metric:"games",operator:">=",value:1}]
                              possibleConditions: [{metric:"maxPossibleCorrectPredictions",operator:">=",value:1}]
                              successConditions: [{metric:"correctPredictions",operator:">=",value:1},{metric:"allGamesFinal",operator:"==",value:true}]
                              failConditions: [{metric:"correctPredictions",operator:"<",value:1},{metric:"allGamesFinal",operator:"==",value:true}]
                            @prizeThatShouldBeAbleToWin.save @prizeThatShouldBeAbleToWin.toJSON(),
                              error: logErrorResponse "@prizeThatShouldBeAbleToWin.save"
                              success: (p) =>
                                @prizeWithoutPrerequisite = new Prize
                                  leagueId: @league.id
                                  name: "prizeWithoutPrerequisite"
                                  description: "two correct picks"
                                  pointValue: 100
                                  eligibleConditions: [{metric:@prizeThatShouldBeAbleToWin.id,operator:">=",value:1},{metric:"games",operator:">=",value:2}]
                                  possibleConditions: [{metric:"maxPossibleCorrectPredictions",operator:">=",value:2}]
                                  successConditions: [{metric:"correctPredictions",operator:">=",value:2},{metric:"allGamesFinal",operator:"==",value:true}]
                                  failConditions: [{metric:"correctPredictions",operator:"<",value:2},{metric:"allGamesFinal",operator:"==",value:true}]
                                @prizeWithoutPrerequisite.save @prizeWithoutPrerequisite.toJSON(),
                                  error: logErrorResponse "@prizeThatShouldBeAbleToWin.save"
                                  success: (p) =>
                                    @prizeThatRequiresMoreGames = new Prize
                                      leagueId: @league.id
                                      name: "prizeWithoutPrerequisite"
                                      description: "lucky seven"
                                      pointValue: 777
                                      eligibleConditions: [{metric:"games",operator:"==",value:7}]
                                      possibleConditions: [{metric:"incorrectPredictions",operator:"==",value:0}]
                                      successConditions: [{metric:"incorrectPredictions",operator:"==",value:0},{metric:"allGamesFinal",operator:"==",value:true}]
                                      failConditions: [{metric:"incorrectPredictions",operator:">",value:0},{metric:"allGamesFinal",operator:"==",value:true}]
                                    @prizeThatRequiresMoreGames.save @prizeThatRequiresMoreGames.toJSON(),
                                      error: logErrorResponse "@prizeThatShouldBeAbleToWin.save"
                                      success: (p) =>
                                        callback()
  
  tearDown: (callback) -> 
    console.log "FIXME - delete all models"
    callback()

  testDeterminePrizes: (test) ->
    test.ok @user, "@user is defined"
    test.ok @period, "@period is defined"
    test.ok @userPeriod, "@userPeriod is defined"
    test.ok @prizeThatShouldBeAbleToWin, "prizeThatShouldBeAbleToWin"
    test.ok @prizeWithoutPrerequisite, "prizeWithoutPrerequisite"
    test.ok @prizeThatRequiresMoreGames, "prizeThatRequiresMoreGames"
    @userPeriod.determinePrizes
      error: logErrorResponse "@userPeriod.determinePrizes"
      success: (prizes) =>
        test.equal prizes.length,3
        test.equal prizes[0].id, @prizeThatShouldBeAbleToWin.id, "@prizeThatShouldBeAbleToWin.id"
        test.equal prizes[0].currentStatus.eligible, true, "prizes[0].currentStatus.eligible"
        test.equal prizes[0].currentStatus.possible, true, "prizes[0].currentStatus.possible"
        test.equal prizes[0].currentStatus.success, true, "prizes[0].currentStatus.success"
        test.equal prizes[0].currentStatus.fail, false, "prizes[0].currentStatus.fail"
        test.equal prizes[1].id, @prizeWithoutPrerequisite.id, "@prizeWithoutPrerequisite.id"
        test.equal prizes[1].currentStatus.eligible, false, "prizes[1].currentStatus.eligible"
        test.equal prizes[1].currentStatus.possible, false, "prizes[1].currentStatus.possible"
        test.equal prizes[1].currentStatus.success, false, "prizes[1].currentStatus.success"
        test.equal prizes[1].currentStatus.fail, true, "prizes[1].currentStatus.fail"
        test.equal prizes[2].id, @prizeThatRequiresMoreGames.id, "@prizeThatRequiresMoreGames.id"
        test.equal prizes[2].currentStatus.eligible, false, "prizes[2].currentStatus.eligible"
        test.equal prizes[2].currentStatus.possible, false, "prizes[2].currentStatus.possible"
        test.equal prizes[2].currentStatus.success, false, "prizes[2].currentStatus.success"
        test.equal prizes[2].currentStatus.fail, false, "prizes[2].currentStatus.fail"
        test.done()


testFetchUser: (test) -> test.ok false, "implement testFetchUser"
testFetchPeriod: (test) -> test.ok false, "implement testFetchPeriod"
testFetchGames: (test) -> test.ok false, "implement testFetchGames"
