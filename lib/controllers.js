(function() {
  var controllers, couch, journey, util;

  util = require("util");

  couch = require("./couch");

  journey = require("journey");

  controllers = exports;

  controllers.router = new journey.Router;

  controllers.router.map(function() {
    this.root.bind(function(req, res) {
      return res.send("butterpicks2");
    });
    this.get("/facebook-object").bind(function(req, res, params) {
      if (!params.facebookId) {
        return res.send(403, {}, {
          error: "no facebookId param"
        });
      }
      return couch.db.view("facebookDocs", "allByFacebookId", {
        key: params.facebookId
      }, function(err, body, headers) {
        if (err) return res.send(500, {}, err);
        return res.send(body);
      });
    });
    return this.post("/facebook-object").bind(function(req, res, params) {
      if (!params.facebookId) {
        return res.send(403, {}, {
          error: "no facebookId param"
        });
      }
      if (!params.email) {
        return res.send(403, {}, {
          error: "no email param"
        });
      }
      return couch.db.insert(params, function(err, body, headers) {
        if (err) return res.send(500, {}, err);
        return res.send(body);
      });
    });
  });

}).call(this);
