models = require "../lib/models"
User = models.User

#TODO test createdAt default. loading existing model does not replace with default?

exports.saveNewUser = 
  newUserAttributes:
    facebookId: 751395611
    email: "ben@mainsocial.com" 

  testSaveNewUser: (test) ->
    u = new User(exports.saveNewUser.newUserAttributes)
    test.equal u.isNew(), true
    u.save
      error: (model,response) ->
        console.log "error saving new user in exports.save"
      success: (model,response) ->
        test.equal model.isNew(), false
        test.ok model.get("id")
        test.ok model.get("_id")
        exports.saveNewUser.teardownModel = model
        test.done()

  teardown: (callback) ->
    exports.saveNewUser.teardownModel.destroy
      error: (model,response) ->
        console.log "error destroying model in exports.save"
      success: (model,response) ->
        callback()


exports.fetchByFacebookId =
  userAttributes:
    id: "whatevs"
    facebookId: 751395611
    email: "ben@mainsocial.com"

  setup: (callback) ->
    u = new User(exports.fetchByFacebookId.userAttributes)
    u.save
      error: (model,response) ->
        console.log "error saving fixture model in exports.fetchByFacebookId"
      success: (model,response) ->
        callback()

  testFetchByFacebookId: (test) ->
    User.fetchByFacebookId exports.fetchByFacebookId.userAttributes.facebookId, (err,user) ->
      test.equal err,null
      test.ok user
      test.equal user.get("id"), exports.fetchByFacebookId.userAttributes.id
      test.equal user.get("facebookId"), exports.fetchByFacebookId.userAttributes.facebookId
      test.equal user.get("email"), exports.fetchByFacebookId.userAttributes.email
      test.done()

  teardown: (callback) ->
    u.destroy
      error: (model,response) ->
        console.log "error destroying fixture model in exports.fetchByFacebookId"
      success: (model,response) ->
        callback()




exports.createUser =
  userAttributes:
    facebookId: 751395611
    email: "ben@mainsocial.com"
  
  setup: (callback) ->
    User.fetchByFacebookId exports.createUser.userAttributes.facebookId, (err,user) ->
      return callback() unless user
      user.destroy (err) ->
        callback()

  testCreate: (test) ->
    u = new User(exports.createUser.userAttributes)
    test.ok u
    test.equal u.get("facebookId"), exports.createUser.userAttributes.facebookId
    test.equal u.get("email"), exports.createUser.userAttributes.email
    u.save()

    test.done()
