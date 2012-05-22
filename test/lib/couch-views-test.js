(function() {
  var assert, batch, couch, couchViewsTest, vows, _;

  vows = require("vows");

  assert = require("assert");

  _ = require("underscore");

  couch = require("couch");

  couchViewsTest = vows.describe("the couch views");

  batch = couchViewsTest.addBatch({
    "get user by facebook id": {
      topic: function() {
        return couch.db.view("users/byFacebookId", {
          key: params.gaekey,
          include_docs: true
        }, this.callback);
      },
      "does not return an error": function(err, data) {
        return assert.isNull(err);
      }
    }
  });

  batch.run();

}).call(this);
