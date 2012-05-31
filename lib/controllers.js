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
        return res.send(400, {}, {
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
    this.post("/user/create").bind(function(req, res, params) {
      if (!params.facebookId) {
        return res.send(400, {}, {
          error: "no facebookId param"
        });
      }
      if (!params.email) {
        return res.send(400, {}, {
          error: "no email param"
        });
      }
      return couch.db.view("facebookObjects", "allByFacebookId", {
        key: params.facebookId
      }, function(err, body, headers) {
        var u;
        if (err) return res.send(500, {}, err);
        if (body.rows.length > 0) return res.send(409, {}, "user already exists");
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
    this.get("/butters").bind(function(req, res, params) {
      var viewParams;
      if (!params.userId) {
        return res.send(400, {}, {
          error: "no userId param"
        });
      }
      viewParams = {
        group_level: 1,
        startkey: [params.userId, '1970-01-01T00:00:00.000Z'],
        endkey: [params.userId, '2070-01-01T00:00:00.000Z']
      };
      return couch.db.view("butters", "byUserId", viewParams, function(err, body, headers) {
        var value;
        if (err) return res.send(500, {}, err);
        value = body.rows.length ? body.rows[0].value : null;
        return res.send({
          userId: params.userId,
          butters: value
        });
      });
    });
    return this.get("/period").bind(function(req, res, params) {
      var d, dateString, p, periodId;
      if (!params.category) {
        return res.send(400, {}, {
          error: "no category param"
        });
      }
      if (!params.leagueStatsKey) {
        return res.send(400, {}, {
          error: "no leagueStatsKey param"
        });
      }
      switch (params.category) {
        case "daily":
          if (!params.date) {
            return res.send(400, {}, {
              error: "no date param"
            });
          }
          d = new Date(params.date);
          dateString = "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
          periodId = "" + params.leagueStatsKey + "_" + params.category + "_" + dateString;
          break;
        case "lifetime":
          periodId = "" + params.leagueStatsKey + "_" + params.category;
      }
      p = new models.Period({
        id: periodId
      });
      return p.fetch({
        error: function(model, response) {
          console.log("doesn't exist? TODO create it");
          return res.send(response);
        },
        success: function(model, response) {
          return res.send(model.toJSON());
        }
      });
    });
  });

}).call(this);
