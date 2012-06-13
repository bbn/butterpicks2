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
Period = models.Period
UserPeriod = models.UserPeriod


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
    u = new User({ id:id })
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
    u = new User({ id:@userId })
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
        @periodData = 
          league:
            statsKey: "iybybkygboo87787878t87g"
          category: "daily"
          startDate: new Date("Jan 21, 2012")
          endDate: new Date("Jan 22, 2012")
        @periodData.id = Period.getCouchId
          category: @periodData.category
          date: @periodData.startDate
          leagueStatsKey: @periodData.league.statsKey
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
          success: -> callback()

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
            test.ok response.body.data
            userPeriodData = response.body.data
            test.equal userPeriodData.id, userPeriod.id
            test.equal userPeriodData.userId, @user.id
            test.equal userPeriodData.leagueStatsKey, @period.get("league").statsKey
            test.equal userPeriodData.periodCategory, @period.get("category")
            test.equal userPeriodData.periodStartDate, @period.get("startDate").toJSON()
            userPeriod.destroy
              error: logErrorResponse "userPeriod.destroy"
              success: -> test.done()

  testUserPeriodGetControllerOnlyPeriodId: (test) ->
    x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.ok response.body.data
      userPeriodData = response.body.data
      test.equal userPeriodData.length, 0
      params = 
        userId: @user.id
        periodId: @period.id
      UserPeriod.createForUserAndPeriod params,
        error: logErrorResponse "UserPeriod.createForUserAndPeriod"
        success: (userPeriod,response) =>
          x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body.data
            userPeriodData = response.body.data
            test.equal userPeriodData.length, 1
            userPeriodData = userPeriodData[0]
            test.equal userPeriodData.userId, @user.id
            test.equal userPeriodData.leagueStatsKey, @period.get("league").statsKey
            test.equal userPeriodData.periodCategory, @period.get("category")
            test.equal userPeriodData.periodStartDate, @period.get("startDate").toJSON()
            user2 = new User()
            user2.save user2.toJSON(),
              error: logErrorResponse "user2.save"
              success: (user2,response) =>
                UserPeriod.createForUserAndPeriod {userId:user2.id,periodId:@period.id},
                  error: logErrorResponse "UserPeriod.createForUserAndPeriod"
                  success: (userPeriod2,response) =>
                    x = mock.get "/user-period?periodId=#{@period.id}", { accept:"application/json" }
                    x.on "success", (response) =>
                      test.ok response
                      test.ok response.body.data
                      userPeriodData = response.body.data
                      test.equal userPeriodData.length, 2
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
    x = mock.get "/user-period?userId=#{@user.id}&leagueStatsKey=#{@period.get('league').statsKey}", { accept:"application/json" }
    x.on "success", (response) =>
      test.ok response
      test.ok response.body.data
      userPeriodData = response.body.data
      test.equal userPeriodData.length, 0
      UserPeriod.createForUserAndPeriod {userId:@user.id,periodId:@period.id},
        error: logErrorResponse "UserPeriod.createForUserAndPeriod"
        success: (userPeriod,response) =>
          x = mock.get "/user-period?userId=#{@user.id}&leagueStatsKey=#{@period.get('league').statsKey}", { accept:"application/json" }
          x.on "success", (response) =>
            test.ok response
            test.ok response.body.data
            userPeriodData = response.body.data
            test.equal userPeriodData.length, 1
            userPeriod.destroy
              error: logErrorResponse "userPeriod.destroy"
              success: -> test.done()