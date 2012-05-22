vows = require "vows"
assert = require "assert"
_ = require "underscore"

couch = require "couch"  

couchViewsTest = vows.describe "the couch views"  
batch = couchViewsTest.addBatch 

  "get user by facebook id":
    topic: ->
      couch.db.view "users/byFacebookId", { key: params.gaekey, include_docs: true }, @callback

    "does not return an error": (err,data) ->
      assert.isNull err

    # "returns the expected documents": (err,data) ->
    #   assert.


batch.run()