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

User = models.User
ButterTransaction = models.ButterTransaction
Period = models.Period
UserPeriod = models.UserPeriod
Game = models.Game
Pick = models.Pick
League = models.League


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.testRootGet = (test) ->
  x = mock.get '/', { accept: "application/json" }
  x.on 'success', (response) ->
    test.ok response
    test.equal response.body.journey,"butterpicks2"
    test.equal response.status, 200 
    test.done()


exports.testGetFacebookObjectMissingFacebookId = (test) ->
  x = mock.get '/facebook-object', { accept: "application/json" }
  x.on 'error', (response) -> console.log "response: #{util.inspect response}"
  x.on 'success', (response) ->
    test.ok response
    test.equal response.body.error,"no facebookId param"
    test.equal response.status, 400
    test.done()


exports.testGetFacebookObjectUser = 

  setUp: (callback) ->
    u = new User
      facebookId: 123456789
    u.save u.toJSON(),
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) =>
        @user = model
        callback()

  testGetFacebookObjectUser: (test) ->
    u = @user
    test.ok u, "cached model is ok"
    facebookId = u.get "facebookId"
    test.ok facebookId, "cached model's faceboookId is ok"
    url = "/facebook-object?facebookId=#{facebookId}"
    x = mock.get url, { accept: "application/json" }
    x.on "success", (response) ->
      test.ok response, "response is ok"
      test.equal response.body.error,null,"error should be null"
      test.equal response.status, 200, "status should be 200"
      test.done()

  tearDown: (callback) -> 
    return callback() unless @user
    u = @user
    u.destroy
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: -> callback()


exports.testCreateUser = 

  testCreateUser: (test) ->
    newUserData = 
      facebookId: 123456789098765
      email: "blerg@lala.mx"
    x = mock.post "/user", { accept: "application/json" }, JSON.stringify newUserData
    x.on "success", (response) =>
      test.ok response, "response is ok"
      test.equal response.status, 201, "status should be 201. response: #{util.inspect response}"
      test.ok response.body.id, "should return a new id"
      test.equal response.body.facebookId, newUserData.facebookId, "facebookId the same"
      test.equal response.body.email, newUserData.email, "email the same"
      @returnedId = response.body.id
      test.done()

  tearDown: (callback) ->
    id = @returnedId
    u = new User({ _id:id })
    u.fetch
      error: (model,response) -> console.log "u.fetch response: #{util.inspect response}"
      success: (model,response) ->
        model.destroy
          error: (model,response) -> console.log "model.destroy response: #{util.inspect response}"
          success: -> callback()


exports.testCreateUserWhoAlreadyExists = 

  setUp: (callback) ->
    @userData = 
      facebookId: 3477728213
      email: "whtaev@kdsj.mx"
    x = mock.post "/user", { accept:"application/json" }, JSON.stringify @userData
    x.on "success", (response) =>
      @userId = response.body.id
      callback()

  testCreateUserWhoAlreadyExists: (test) ->
    x = mock.post "/user", { accept:"application/json" }, JSON.stringify @userData
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,409
      test.equal response.body, "user already exists"
      test.done()

  tearDown: (callback) ->
    u = new User({ _id:@userId })
    u.fetch
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) ->
        model.destroy
          error: (model,response) -> console.log "response: #{util.inspect response}"
          success: -> callback()


exports.testUserPeriodGetController = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @leagueStatsKey = "dlkajshno8y3n4lkjhsad"
        @league = new League
          statsKey: @leagueStatsKey
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: (model,response) =>
            @periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Jan 21, 2012")
              endDate: new Date("Jan 22, 2012")
            @periodData.id = Period.getCouchId
              category: @league.get "basePeriodCategory"
              date: @periodData.startDate
              leagueId: @league.id
            @period = new Period(@periodData)
            @period.save @period.toJSON(),
              error: logErrorResponse "saving period"
              success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @period.destroy
          error: logErrorResponse "destroying period"
          success: => 
            @league.destroy
              success: => callback()

  testUserPeriodGetController: (test) ->
    test.ok @user.id
    test.ok @period.id
    x = mock.get "/user-period?userId=#{@user.id}&periodId=#{@period.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      params = 
        userId: @user.id
        periodId: @period.id
      UserPeriod.createForUserAndPeriod params,
        error: logErrorResponse "UserPeriod.createForUserAndPeriod"
        success: (userPeriod,response) =>
          x = mock.get "/user-period?userId=#{@user.id}&periodId=#{@period.id}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body
            userPeriodData = response.body
            test.equal userPeriodData.id, userPeriod.id
            test.equal userPeriodData.userId, @user.id
            test.equal userPeriodData.leagueId, @period.get("leagueId")
            test.equal userPeriodData.category, @period.get("basePeriodCategory")
            test.equal userPeriodData.periodCategory, @period.get("category")
            test.equal userPeriodData.periodStartDate, @period.get("startDate").toJSON()
            userPeriod.destroy
              error: logErrorResponse "userPeriod.destroy"
              success: -> test.done()

  testUserPeriodGetControllerOnlyPeriodId: (test) ->
    x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.ok response.body
      userPeriodData = response.body
      test.equal userPeriodData.length, 0
      params = 
        userId: @user.id
        periodId: @period.id
      UserPeriod.createForUserAndPeriod params,
        error: logErrorResponse "UserPeriod.createForUserAndPeriod"
        success: (userPeriod,response) =>
          test.ok userPeriod.id
          test.equal userPeriod.get("metrics").points,0
          x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body
            userPeriodData = response.body
            test.equal userPeriodData.length, 1
            userPeriodData = userPeriodData[0]
            test.equal userPeriodData.userId, @user.id
            test.equal userPeriodData.leagueId, @period.get("leagueId")
            test.equal userPeriodData.periodCategory, @period.get("category")
            test.equal userPeriodData.periodStartDate, @period.get("startDate").toJSON()
            test.ok userPeriodData.metrics
            test.equal userPeriodData.metrics.points,0
            user2 = new User()
            user2.save user2.toJSON(),
              error: logErrorResponse "user2.save"
              success: (user2,response) =>
                UserPeriod.createForUserAndPeriod {userId:user2.id,periodId:@period.id},
                  error: logErrorResponse "UserPeriod.createForUserAndPeriod"
                  success: (userPeriod2,response) =>
                    test.equal userPeriod2.get("metrics").points,0
                    userPeriod2.save {metrics:{points:1}}, 
                      error: logErrorResponse "userPeriod2.save"
                      success: (userPeriod2,response) =>
                        x = mock.get "/user-period?periodId=#{@period.id}&descending=true", { accept:"application/json" }
                        x.on "success", (response) =>
                          test.ok response
                          test.ok response.body
                          userPeriodData = response.body
                          test.equal userPeriodData.length, 2
                          test.equal userPeriodData[0].metrics.points,1
                          test.equal userPeriodData[1].metrics.points,0
                          x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
                          x.on "success", (response) =>
                            test.ok response
                            test.ok response.body
                            userPeriodData = response.body
                            test.equal userPeriodData.length, 2
                            test.equal userPeriodData[0].metrics.points,0
                            test.equal userPeriodData[1].metrics.points,1
                            userPeriod.destroy
                              error: logErrorResponse "userPeriod.destroy"
                              success: -> 
                                userPeriod2.destroy
                                  error: logErrorResponse "userPeriod2.destroy"
                                  success: ->
                                    user2.destroy
                                      error: logErrorResponse "user2.destroy"
                                      success: -> test.done()

            



  testUserPeriodGetControllerOnlyUserId: (test) ->
    x = mock.get "/user-period?userId=#{@user.id}&leagueId=#{@period.get('leagueId')}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.ok response.body
      userPeriodData = response.body
      test.equal userPeriodData.length, 0, "userPeriodData.length 1"
      UserPeriod.createForUserAndPeriod {userId:@user.id,periodId:@period.id},
        error: logErrorResponse "UserPeriod.createForUserAndPeriod"
        success: (userPeriod,response) =>
          test.ok response
          x = mock.get "/user-period?userId=#{@user.id}&leagueId=#{@period.get('leagueId')}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body
            userPeriodData = response.body
            test.equal userPeriodData.length, 1, "userPeriodData.length 2"
            userPeriod.destroy
              error: logErrorResponse "userPeriod.destroy"
              success: -> test.done()



exports.testPickGet = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game()
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: -> callback()

  testPickGet: (test) ->
    test.ok @user.id
    test.ok @game.id
    x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      Pick.create 
        gameId:@game.id
        userId:@user.id
        error: logErrorResponse "pick.save"
        success: (pick,response) =>
          x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body
            pickData = response.body
            test.equal pickData.id, pick.id
            test.equal pickData.userId, @user.id
            test.equal pickData.gameId, @game.id
            pick.destroy
              error: logErrorResponse "pick.destroy"
              success: -> test.done()


exports.testPickPost = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: -> callback()

  testPickPost: (test) ->
    test.ok @user.id
    test.ok @game.id
    x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      pickData = 
        userId: @user.id
        gameId: @game.id
        home: true
        away: false
        draw: false
        butter: false
      x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
      x.on "success", (response) =>
        test.ok response, "response is ok"
        test.equal response.status, 201, "status should be 201. response: #{util.inspect response}"
        test.ok response.body
        data = response.body
        test.ok data.id, "should return a new id"
        test.equal data.id, Pick.getCouchId(pickData)
        test.equal data.userId, @user.id
        test.equal data.gameId, @game.id
        test.equal data.home, true, "data.home"
        test.equal data.away, false
        test.equal data.draw, false
        test.equal data.butter, false
        Pick.fetchForUserAndGame pickData,
          error: logErrorResponse "Pick.fetchForUserAndGame"
          success: (pick,response) =>
            test.ok pick
            test.equal pick.id, Pick.getCouchId(pickData)
            test.equal pick.get("userId"), @user.id
            test.equal pick.get("gameId"), @game.id
            test.equal pick.get("home"), true
            test.equal pick.get("away"), false
            test.equal pick.get("draw"), false
            test.equal pick.get("butter"), false 
            x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
            x.on "success", (response) =>
              test.ok response, "response is ok"
              test.equal response.status, 409, "model should already exist"
              pick.destroy
                error: logErrorResponse "pick.destroy"
                success: (pick,response) -> test.done()


exports.testPickPostForExpiredGame = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:-7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: -> callback()

  testPickPostForExpiredGame: (test) ->
    test.ok @user.id
    test.ok @game.id
    x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      pickData = 
        userId: @user.id
        gameId: @game.id
        home: true
        away: false
        draw: false
        butter: false
      x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
      x.on "success", (response) =>
        test.ok response, "response is ok"
        test.equal response.status, 400, "status should be 400 - game has passed."
        Pick.fetchForUserAndGame pickData,
          success: -> console.log "this is unexpected."
          error: (_,response) =>
            test.equal response.status_code, 404
            test.done()


exports.testPickPostForInvalidParams = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: -> callback()

  testPickPostForInvalidParams: (test) ->
    test.ok @user.id
    test.ok @game.id
    x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      pickData = 
        userId: @user.id
        gameId: @game.id
        home: true
        away: true #can't have both true!
        draw: false
        butter: false
      x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
      x.on "success", (response) =>
        test.ok response, "response is ok"
        test.equal response.status, 400, "status should be 400 - invalid params."
        Pick.fetchForUserAndGame pickData,
          success: -> console.log "this is unexpected."
          error: (_,response) =>
            test.equal response.status_code, 404
            test.done()


exports.testPickPostWithNoButters = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: -> callback()

  testPickPostWithNoButter: (test) ->
    test.ok @user.id
    test.ok @game.id
    x = mock.get "/pick?userId=#{@user.id}&gameId=#{@game.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,404
      pickData = 
        userId: @user.id
        gameId: @game.id
        home: false
        away: false
        draw: false
        butter: true
      x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
      x.on "success", (response) =>
        test.ok response, "response is ok"
        test.equal response.status, 400, "status should be 400 - no butter."
        Pick.fetchForUserAndGame pickData,
          success: -> logErrorResponse "Pick.fetchForUserAndGame"
          error: (_,response) =>
            test.equal response.status_code, 404
            tr = new ButterTransaction
              userId: @user.id
              amount: 100
              createdDate: new Date()
            tr.save tr.toJSON(),
              error: (model,response) -> console.log "couldn't create ButterTransaction?"
              success: (butterTransaction,response) => 
                @user.getButters
                  error: logErrorResponse "@user.getButters"
                  success: (butters) =>
                    test.equal butters,100
                    x = mock.post "/pick", { accept: "application/json" }, JSON.stringify pickData
                    x.on "success", (response) =>
                      test.ok response, "response is ok"
                      test.equal response.status, 201, "status should be 201. response: #{util.inspect response}"
                      test.ok response.body
                      data = response.body
                      test.ok data.id, "should return a new id"
                      test.equal data.id, Pick.getCouchId(pickData)
                      test.equal data.userId, @user.id
                      test.equal data.gameId, @game.id
                      test.equal data.home, false
                      test.equal data.away, false
                      test.equal data.draw, false
                      test.equal data.butter, true
                      @user.getButters
                        error: logErrorResponse "@user.getButters 2"
                        success: (butters) =>
                          test.equal butters,99
                          Pick.fetchForUserAndGame pickData,
                            error: logErrorResponse "Pick.fetchForUserAndGame"
                            success: (pick,response) =>
                              test.ok pick
                              pick.destroy
                                error: logErrorResponse "pick.destroy"
                                success: =>
                                  @user.fetchButterTransactions
                                    error: logErrorResponse "@user.fetchButterTransactions"
                                    success: (trannies) =>
                                      test.equal trannies.length,2
                                      trannies[0].destroy
                                        error: logErrorResponse "trannies[0].destroy"
                                        success: => 
                                          trannies[1].destroy
                                            error: logErrorResponse "trannies[1].destroy"
                                            success: => 
                                              test.done()


exports.testPickPut = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: => 
            Pick.create
              userId:@user.id
              gameId:@game.id
              error: logErrorResponse "Pick.create"
              success: (pick,response) =>
                @pick = pick
                callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: => 
            pick = new Pick {_id:@pick.id}
            pick.fetch
              error: logErrorResponse "pick.fetch"
              success: (pick,response) =>            
                pick.destroy
                  error: logErrorResponse "destroying pick testPickPut"
                  callback()

  testPickPut: (test) ->
    test.ok @user.id
    test.ok @game.id
    test.ok @pick.id
    pickData =
      id: @pick.id
      userId: @user.id
      gameId: @game.id
      home: true
      away: false
      draw: false
      butter: false
    x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
    x.on "success", (response) =>
      test.ok response
      test.equal response.status,200
      test.ok response.body
      data = response.body
      for key,val of pickData
        test.equal data[key],val
      pickData.home = false
      pickData.away = true
      x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
      x.on "success", (response) =>
        test.ok response
        test.equal response.status,200
        test.ok response.body
        for key,val of pickData
          test.equal response.body[key],val
        pickData.home = true
        pickData.away = true
        x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
        x.on "success", (response) =>
          test.ok response
          test.equal response.status,400, "invalid pick params"
          @game.save {startDate: (new Date()).add({days:-7})},
            error: logErrorResponse "resaving Game with earlier start"
            success: (game,response) =>
              pickData.away = false
              pickData.home = true
              pickData.draw = false
              x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
              x.on "success", (response) =>
                test.ok response
                test.equal response.status,400,"game should be too early"
                test.done()



exports.testPickButters = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @game = new Game
          startDate: (new Date()).add({days:7})
        @game.save @game.toJSON(),
          error: -> logErrorResponse "saving game"
          success: => 
            pickData = 
            Pick.create
              userId: @user.id
              gameId: @game.id
              home: false
              away: false
              butter: false
              error: logErrorResponse "Pick.create"
              success: (pick,response) =>
                @pick = pick
                callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @game.destroy
          error: logErrorResponse "destroying game"
          success: => 
            pick = new Pick {_id:@pick.id}
            pick.fetch
              error: logErrorResponse "pick.fetch in tearDown"
              success: (pick,response) => 
                pick.destroy
                  error: logErrorResponse "destroying pick"
                  success: => callback()

  testPickPutButters: (test) ->
    test.ok @user.id
    test.ok @game.id
    test.ok @pick.id
    @user.getButters
      error: logErrorResponse "@user.getButters"
      success: (butters) =>
        test.equal butters,null,"butters should be null"
        pickData =
          id: @pick.id
          userId: @user.id
          gameId: @game.id
          home: false
          away: false
          draw: false
          butter: true
        x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
        x.on "success", (response) =>
          test.ok response
          test.equal response.status,400,"should have no butters"
          pick = new Pick {_id:@pick.id}
          pick.fetch
            error: logErrorResponse "pick.fetch"
            success: (pick,response) =>
              test.equal pick.get("butter"),false,"butter should still be false"
              tr = new ButterTransaction
                userId: @user.id
                amount: 100
                createdDate: new Date()
              tr.save tr.toJSON(),
                error: (model,response) -> console.log "couldn't create ButterTransaction?"
                success: (butterTransaction,response) => 
                  @user.getButters
                    error: logErrorResponse "@user.getButters"
                    success: (butters) =>
                      test.equal butters,100,"should now have 100 butters"
                      x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
                      x.on "success", (response) =>
                        test.ok response
                        test.equal response.status,200,"should be 200 when user has butters"
                        test.ok response.body
                        for key,val of pickData
                          test.equal response.body[key],val,"test for #{key}"
                        pick = new Pick {_id:@pick.id}
                        pick.fetch
                          error: logErrorResponse "pick.fetch"
                          success: (pick,response) =>
                            test.equal pick.get("butter"),true,"butter now true"
                            @user.getButters
                              error: logErrorResponse "@user.getButters"
                              success: (butters) =>
                                test.equal butters,99
                                pickData.butter = false
                                x = mock.put "/pick", { accept:"application/json" }, JSON.stringify pickData
                                x.on "success", (response) =>
                                  test.ok response
                                  test.equal response.status,200
                                  test.ok response.body
                                  for key,val of pickData
                                    test.equal response.body[key],val
                                  pick = new Pick {_id:@pick.id}
                                  pick.fetch
                                    error: logErrorResponse "pick.fetch"
                                    success: (pick,response) =>
                                      test.equal pick.get("butter"),false,"butter now false"
                                      @user.getButters
                                        error: logErrorResponse "@user.getButters"
                                        success: (butters) =>
                                          test.equal butters,100
                                          @user.fetchButterTransactions
                                            error: logErrorResponse "@user.fetchButterTransactions"
                                            success: (trannies) =>
                                              test.equal trannies.length,3
                                              trannies[0].destroy
                                                error: logErrorResponse "trannies[0].destroy"
                                                success: => 
                                                  trannies[1].destroy
                                                    error: logErrorResponse "trannies[1].destroy"
                                                    success: => 
                                                      trannies[2].destroy
                                                        error: logErrorResponse "trannies[1].destroy"
                                                        success: => 
                                                          test.done()
