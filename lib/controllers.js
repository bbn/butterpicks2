(function() {
  var couch, journey, models, util;

  util = require("util");

  couch = require("./couch");

  models = require("./models");

  journey = require("journey");

  exports.router = new journey.Router;

  exports.router.map(function() {
    this.root.bind(function(req, res) {
      return res.send("butterpicks2");
    });
    this.get("/facebook-object").bind(function(req, res, params) {
      if (!params.facebookId) {
        return res.send(403, {}, {
          error: "no facebookId param"
        });
      }
      return couch.db.view("facebookObjects", "allByFacebookId", {
        key: params.facebookId
      }, function(err, body, headers) {
        if (err) return res.send(500, {}, err);
        return res.send(body);
      });
    });
    return this.post("/user/create").bind(function(req, res, params) {
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
      return couch.db.view("facebookObjects", "allByFacebookId", {
        key: params.facebookId
      }, function(err, body, headers) {
        var u;
        if (err) return res.send(500, {}, err);
        if (body.rows.length > 0) return res.send(500, {}, "user already exists");
        params.createdDate = new Date();
        u = new models.User(params);
        return u.save(u.toJSON(), {
          error: function(model, response) {
            return res.send(500, {}, response);
          },
          success: function(model, response) {
            return res.send(200, {}, {
              id: model.id,
              facebookId: model.get("facebookId"),
              email: model.get("email")
            });
          }
        });
      });
    });
  });

}).call(this);
