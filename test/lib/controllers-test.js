(function() {
  var assert, batch, controllerTests, controllers, del, get, journey, mock, mockRequest, post, put, resources, vows, _;

  vows = require("vows");

  assert = require("assert");

  _ = require("underscore");

  journey = require("journey");

  controllers = require("../../lib/controllers");

  mockRequest = require("../../node_modules/journey/lib/journey/mock-request");

  mock = mockRequest.mock(controllers.router);

  get = mock.get;

  del = mock.del;

  post = mock.post;

  put = mock.put;

  journey.env = "test";

  resources = {
    docWithoutKey: {
      doctype: "sdasda",
      bla: "bla"
    },
    docWithoutDoctype: {
      gaekey: "1982n9p21un3p9",
      bla: "bla"
    },
    user: {
      doctype: "user",
      gaekey: "dlaskjx01mumdalsjdalskje0921uxmaksl",
      email: "user@user.com"
    }
  };

  controllerTests = vows.describe("the controllers");

  batch = controllerTests.addBatch({
    "root": {
      topic: function() {
        return get('/', {
          accept: "application/json"
        });
      },
      "does not totally fail": function(response) {
        return assert.isDefined(response);
      },
      "responds with 'hello'": function(response) {
        return assert.equal(response.body.journey, "welcome");
      },
      "status is 200": function(response) {
        return assert.equal(response.status, 200);
      }
    },
    "/from-gae/couchmodel-put GET": {
      topic: function() {
        return get('/from-gae/couchmodel-put', {
          accept: "application/json"
        });
      },
      "status is 405": function(response) {
        return assert.equal(response.status, 405);
      },
      "response is 'method not allowed'": function(response) {
        assert.isDefined(response.body.error);
        return assert.equal(response.body.error, "method not allowed.");
      }
    },
    "/from-gae/couchmodel-put POST doc without gaekey": {
      topic: function() {
        return post('/from-gae/couchmodel-put', {
          accept: "application/json"
        }, JSON.stringify(resources.docWithoutKey));
      },
      "status is 403": function(response) {
        return assert.equal(response.status, 403);
      },
      "error is 'no gaekey'": function(response) {
        assert.isDefined(response.body.error);
        return assert.equal(response.body.error, 'no gaekey');
      }
    },
    "/from-gae/couchmodel-put POST doc without doctype": {
      topic: function() {
        return post('/from-gae/couchmodel-put', {
          accept: "application/json"
        }, JSON.stringify(resources.docWithoutDoctype));
      },
      "status is 403": function(response) {
        return assert.equal(response.status, 403);
      },
      "error is 'no key'": function(response) {
        assert.isDefined(response.body.error);
        return assert.equal(response.body.error, 'no doctype');
      }
    },
    "/from-gae/couchmodel-put POST user doc": {
      topic: function() {
        return post('/from-gae/couchmodel-put', {
          accept: "application/json"
        }, JSON.stringify(resources.user));
      },
      "status is 202 (Accepted)": function(response) {
        return assert.equal(response.status, 202);
      },
      "responds with data properly": function(response) {
        var key, val, _ref, _results;
        _ref = resources.user;
        _results = [];
        for (key in _ref) {
          val = _ref[key];
          _results.push(assert.equal(response.body.key, resources.user.key));
        }
        return _results;
      }
    }
  });

  batch.run();

}).call(this);
