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

