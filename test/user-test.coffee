util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

User = models.User

#TODO test createdAt default. loading existing model does not replace with default?



exports.createUser = 

  testCreateUser: (test) ->
    newUserAttributes =
      facebookId: 751395611
      email: "ben@mainsocial.com" 
    u = new User(newUserAttributes)
    test.equal u.isNew(), true, "u.isNew()"
    u.save u.toJSON(),
      error: (model,response) ->
        console.log "error saving new user in exports.save"
      success: (model,response) ->
        test.equal model.isNew(), false
        test.ok model.id, "has id"
        test.ok model.get("_rev"), "has _rev"
        test.equal model.get("facebookId"), newUserAttributes.facebookId
        test.equal model.get("email"), newUserAttributes.email
        exports.createUser.teardownModel = model
        test.done()

  tearDown: (callback) ->
    exports.createUser.teardownModel.destroy
      error: (model,response) -> console.log "error destroying model in exports.save"
      success: (model,response) -> callback()


exports.testFetchUser = 

  setUp: (callback) ->
    @userAttributes = 
      facebookId: 751395611
      email: "ben@mainsocial.com" 
    u = new User(@userAttributes)
    u.save u.toJSON(),
      error: (model,response) -> console.log "error saving new user"
      success: (model,response) =>
        @userId = model.id
        callback()

  testFetchUser: (test) ->
    id = @userId
    test.ok id, "should have passed an id via this keyword"
    u = new User({ id:id })
    u.fetch
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) =>
        test.ok model
        test.equal model.id, id, "same id"
        test.equal model.get("facebookId"),@userAttributes.facebookId,"same facebookId"
        test.equal model.get("email"),@userAttributes.email,"same email"
        test.done()

  tearDown: (callback) ->
    id = @userId
    u = new User({ id:id })
    u.fetch
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) ->
        model.destroy
          error: (model,response) -> console.log "response: #{util.inspect response}"
          success: -> callback()