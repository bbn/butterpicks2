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
    x = mock.post "/user/create", { accept: "application/json" }, JSON.stringify newUserData
    x.on "success", (response) =>
      test.ok response, "response is ok"
      test.equal response.status, 200, "status should be 200. response: #{util.inspect response}"
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
    x = mock.post "/user/create", { accept: "application/json" }, JSON.stringify @userData
    x.on "success", (response) =>
      @userId = response.body.id
      callback()

  testCreateUserWhoAlreadyExists: (test) ->
    x = mock.post "/user/create", { accept: "application/json" }, JSON.stringify @userData
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