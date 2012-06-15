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
    this.get("/pick").bind(function(req, res, params) {
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
    this.post("/pick").bind(function(req, res, params) {
      var game;
      console.log("FIXME - doesn't take butters into account");
      if (!(params.userId && params.gameId)) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      game = new Game({
        id: params.gameId
      });
      return game.fetch({
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(game, response) {
          var pick;
          if (game.deadlineHasPassed()) {
            return res.send(400, {}, "deadlineHasPassed");
          }
          pick = new Pick(params);
          pick.game = game;
          if (!pick.editable()) return res.send(400, {}, "not editable");
          if (!pick.isValid()) return res.send(400, {}, "invalid");
          return Pick.create(params, {
            error: function(_, response) {
              return res.send(response.status_code, {}, response);
            },
            success: function(data, response) {
              return res.send(data);
            }
          });
        }
      });
    });
    return this.put("/pick").bind(function(req, res, params) {
      var pick;
      console.log("FIXME - doesn't take butters into account");
      if (!params.id) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      pick = new Pick({
        id: params.id
      });
      return pick.fetch({
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(pick, response) {
          var game;
          game = new Game({
            id: pick.get("gameId")
          });
          return game.fetch({
            error: function(_, response) {
              return res.send(response.status_code, {}, response);
            },
            success: function(game, response) {
              if (game.deadlineHasPassed()) {
                return res.send(400, {}, "deadlineHasPassed");
              }
              pick.game = game;
              if (!pick.editable()) return res.send(400, {}, "not editable");
              if (!pick.set(params)) return res.send(400, {}, "invalid params");
              pick.set({
                updatedDate: new Date()
              });
              return pick.save(pick.toJSON(), {
                error: function(_, response) {
                  return res.send(response.status_code, {}, response);
                },
                success: function(pick, response) {
                  return res.send(pick.toJSON());
                }
              });
            }
          });
        }
      });
    });
  });

}).call(this);
