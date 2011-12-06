vows = require "vows"
assert = require "assert"
_ = require "underscore"

journey = require "journey"
controllers = require "../../lib/controllers"

mockRequest = require "../../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
get = mock.get
del = mock.del
post = mock.post
put = mock.put
journey.env = "test"

resources = 
  docWithoutKey:
    doctype: "sdasda"
    bla: "bla"
  docWithoutDoctype:
    gaekey: "1982n9p21un3p9"
    bla: "bla"
  user: 
    doctype: "user"
    gaekey: "dlaskjx01mumdalsjdalskje0921uxmaksl"
    email: "user@user.com"
  

controllerTests = vows.describe "the controllers"  
batch = controllerTests.addBatch 

  "root":
    topic: ->
      get '/', { accept: "application/json" }
      
    "does not totally fail": (response) ->
      assert.isDefined response
    
    "responds with 'hello'": (response) ->
      assert.equal response.body.journey, "welcome"
      
    "status is 200": (response) ->
      assert.equal response.status, 200
      
      
  "/from-gae/couchmodel-put GET":
    topic: ->
      get '/from-gae/couchmodel-put', { accept: "application/json" }
      
    "status is 405": (response) ->
      assert.equal response.status, 405
      
    "response is 'method not allowed'": (response) ->
      assert.isDefined response.body.error
      assert.equal response.body.error, "method not allowed."
      
      
  "/from-gae/couchmodel-put POST doc without gaekey":
    topic: ->
      post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.docWithoutKey

    "status is 403": (response) ->
      assert.equal response.status, 403
      
    "error is 'no gaekey'": (response) ->
      assert.isDefined response.body.error
      assert.equal response.body.error, 'no gaekey'

  "/from-gae/couchmodel-put POST doc without doctype":
    topic: ->
      post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.docWithoutDoctype

    "status is 403": (response) ->
      assert.equal response.status, 403

    "error is 'no key'": (response) ->
      assert.isDefined response.body.error
      assert.equal response.body.error, 'no doctype'


      
  "/from-gae/couchmodel-put POST user doc":
    topic: ->
      post '/from-gae/couchmodel-put', {accept: "application/json" }, JSON.stringify resources.user
      
    "status is 202 (Accepted)": (response) ->
      assert.equal response.status, 202
      
    "responds with data properly": (response) ->
      for key, val of resources.user
        assert.equal response.body.key, resources.user.key

      
        
    
    

batch.run()