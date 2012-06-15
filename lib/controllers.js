(function() {
  var Game, Period, Pick, User, UserPeriod, couch, journey, models, request, util, _;

  require("./date");

  _ = require("underscore");

  util = require("util");

  request = require("request");

  couch = require("./couch");

  models = require("./models");

  require("./model-server-utils");

  Game = models.Game;

  Period = models.Period;

  User = models.User;

  UserPeriod = models.UserPeriod;

  Pick = models.Pick;

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
        if (err) return res.send(err.status_code, {}, err);
        return res.send({
          requestParams: params,
          data: body
        });
      });
    });
    this.post("/user").bind(function(req, res, params) {
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
        var u, uParams;
        if (err) return res.send(500, {}, err);
        if (body.rows.length > 0) return res.send(409, {}, "user already exists");
        uParams = _(params).clone();
        uParams.createdDate = new Date();
        u = new User(uParams);
        return u.save(u.toJSON(), {
          error: function(model, response) {
            return res.send(response.status_code, {}, response);
          },
          success: function(model, response) {
            return res.send({
              requestParams: params,
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
        if (err) return res.send(err.status_code, {}, err);
        value = body.rows.length ? body.rows[0].value : null;
        return res.send({
          requestParams: params,
          butters: value
        });
      });
    });
    this.post("/game").bind(function(req, res, params) {
      return Game.createOrUpdateGameFromStatsAttributes(params, {
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(game, response) {
          return res.send({
            requestParams: params,
            data: game.toJSON()
          });
        }
      });
    });
    this.get("/period").bind(function(req, res, params) {
      var p, param, periodId, _i, _len, _ref;
      _ref = ["category", "leagueStatsKey", "date"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        if (!params[param]) {
          return res.send(400, {}, {
            error: "no " + param + " param"
          });
        }
      }
      periodId = Period.getCouchId(params);
      p = new Period({
        id: periodId
      });
      return p.fetch({
        error: function(model, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(model, response) {
          return res.send({
            requestParams: params,
            data: model.toJSON()
          });
        }
      });
    });
    this.get("/user-period").bind(function(req, res, params) {
      var f;
      if (!((params.userId && params.leagueStatsKey) || params.periodId)) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      if (params.userId && params.periodId) {
        f = UserPeriod.fetchForUserAndPeriod;
      } else if (params.periodId) {
        f = UserPeriod.fetchForPeriod;
      } else if (params.userId && params.leagueStatsKey) {
        f = UserPeriod.fetchForUserAndLeague;
      }
      return f(params, {
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(data, response) {
          return res.send({
            requestParams: params,
            data: data
          });
        }
      });
    });
    return this.get("/pick").bind(function(req, res, params) {
      if (!(params.userId && params.gameId)) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      return Pick.fetchForUserAndGame(params, {
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(data, response) {
          return res.send({
            requestParams: params,
            data: data
          });
        }
      });
    });
  });

}).call(this);
