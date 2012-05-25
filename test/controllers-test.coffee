journey = require "journey"
controllers = require "../lib/controllers"
mockRequest = require "../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
journey.env = "test"


exports.testRootGet = (test) ->
  x = mock.get '/', { accept: "application/json" }
  x.on 'success', (response) ->
    test.ok response
    test.equal response.body.journey,"butterpicks2"
    test.equal response.status, 200 
    test.done()


# /user

exports.testUserGetNoFacebookId = (test) ->
  x = mock.get '/user', { accept: "application/json" }
  x.on 'success', (response) ->
    test.ok response
    test.equal response.body.error,"no facebookId param"
    test.equal response.status, 403 
    test.done()



#       
#   "/from-gae/couchmodel-put POST doc without gaekey":
#     topic: ->
#       post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.docWithoutKey
# 
#     "status is 403": (response) ->
#       assert.equal response.status, 403
#       
#     "error is 'no gaekey'": (response) ->
#       assert.isDefined response.body.error
#       assert.equal response.body.error, 'no gaekey'
# 
#   "/from-gae/couchmodel-put POST doc without doctype":
#     topic: ->
#       post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.docWithoutDoctype
# 
#     "status is 403": (response) ->
#       assert.equal response.status, 403
# 
#     "error is 'no key'": (response) ->
#       assert.isDefined response.body.error
#       assert.equal response.body.error, 'no doctype'
# 
# 
#       
#   "/from-gae/couchmodel-put POST user doc":
#     topic: ->
#       post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.user
#       
#     "status is 202 (Accepted)": (response) ->
#       assert.equal response.status, 202
#       
#     "responds with data properly": (response) ->
#       for key, val of resources.user
#         assert.equal response.body.key, resources.user.key
# 
#       
#         
#     
#     
# 
# batch.run()# 