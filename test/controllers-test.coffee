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
    test.equal response.status, 403 
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
    x.on 'success', (response) ->
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

