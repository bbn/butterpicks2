(function() {
  var ButterTransaction, Game, Period, Pick, User, UserPeriod, couch, journey, models, request, util, _;

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

  ButterTransaction = models.ButterTransaction;

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
        return res.send(body);
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
              id: model.id,
              facebookId: model.get("facebookId"),
              email: model.get("email")
            });
          }
        });
      });
    });
    this.get("/metrics").bind(function(req, res, params) {
      var user;
      user = new User({
        _id: params.userId
      });
      return user.fetch({
        error: function(__, err) {
          return res.send(err.status_code, {}, err);
        },
        success: function(user) {
          if (params.startDate) params.startDate = new Date(params.startDate);
          if (params.endDate) params.endDate = new Date(params.endDate);
          return user.fetchMetrics({
            leagueId: params.leagueId,
            startDate: params.startDate,
            endDate: params.endDate,
            error: function(__, err) {
              return res.send(err.status_code, {}, err);
            },
            success: function(metrics) {
              return res.send(metrics);
            }
          });
        }
      });
    });
    this.get("/butters").bind(function(req, res, params) {
      var u;
      if (!params.userId) {
        return res.send(400, {}, {
          error: "no userId param"
        });
      }
      u = new User({
        _id: params.userId
      });
      return u.getButters({
        error: function(_, err) {
          return res.send(err.status_code, {}, err);
        },
        success: function(value) {
          return res.send(200, {}, value);
        }
      });
    });
    this.post("/game").bind(function(req, res, params) {
      return Game.createOrUpdateGameFromStatsAttributes(params, {
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(game, response) {
          return res.send(game);
        }
      });
    });
    this.get("/period").bind(function(req, res, params) {
      var p, param, periodId, _i, _len, _ref;
      _ref = ["category", "leagueId", "date"];
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
        _id: periodId
      });
      return p.fetch({
        error: function(model, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(model, response) {
          return res.send(model);
        }
      });
    });
    this.get("/user-period").bind(function(req, res, params) {
      var f;
      if (!((params.userId && params.leagueId) || params.periodId)) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      if (params.userId && params.periodId) {
        f = UserPeriod.fetchForUserAndPeriod;
      } else if (params.periodId) {
        f = UserPeriod.fetchForPeriod;
      } else if (params.userId && params.leagueId) {
        f = UserPeriod.fetchForUserAndLeague;
      }
      return f(params, {
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(data, response) {
          return res.send(200, {}, data);
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
          return res.send(data);
        }
      });
    });
    this.post("/pick").bind(function(req, res, params) {
      var errorSent, game, sendError, testUserAndGame, user,
        _this = this;
      if (!(params.userId && params.gameId)) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      user = new User({
        _id: params.userId
      });
      user.getButters({
        error: function(_, response) {
          return sendError(response);
        },
        success: function(butters) {
          user.butters = butters;
          return testUserAndGame({
            user: user
          });
        }
      });
      game = new Game({
        _id: params.gameId
      });
      game.fetch({
        error: function(_, response) {
          return sendError(response);
        },
        success: function(game, response) {
          return testUserAndGame({
            game: game
          });
        }
      });
      errorSent = false;
      sendError = function(couchResponse) {
        if (errorSent) return;
        errorSent = true;
        return res.send(couchResponse.status_code, {}, couchResponse);
      };
      this.game = null;
      this.user = null;
      return testUserAndGame = function(data) {
        var pick;
        if (data.game) _this.game = data.game;
        if (data.user) _this.user = data.user;
        if (!(_this.game && _this.user)) return;
        if (_this.game.deadlineHasPassed()) {
          return res.send(400, {}, "deadlineHasPassed");
        }
        pick = new Pick(params);
        pick.game = _this.game;
        if (!pick.editable()) return res.send(400, {}, "not editable");
        if (!pick.isValid()) return res.send(400, {}, "invalid");
        if (params.butter && (_this.user.butters <= 0)) {
          return res.send(400, {}, "insufficient butter");
        }
        return Pick.create(_(params).extend({
          error: function(_, response) {
            return sendError(response);
          },
          success: function(pick, response) {
            var tr;
            if (!pick.get("butter")) return res.send(pick);
            tr = new ButterTransaction({
              userId: _this.user.id,
              pickId: pick.id,
              amount: -1,
              createdDate: pick.get("createdDate")
            });
            return tr.save(tr.toJSON(), {
              error: function(model, response) {
                return sendError(response);
              },
              success: function(model, response) {
                return res.send(pick);
              }
            });
          }
        }));
      };
    });
    return this.put("/pick").bind(function(req, res, params) {
      var pick;
      if (!params.id) {
        return res.send(400, {}, {
          error: "invalid params"
        });
      }
      pick = new Pick({
        _id: params.id
      });
      return pick.fetch({
        error: function(_, response) {
          return res.send(response.status_code, {}, response);
        },
        success: function(pick, response) {
          var game;
          game = new Game({
            _id: pick.get("gameId")
          });
          return game.fetch({
            error: function(_, response) {
              return res.send(response.status_code, {}, response);
            },
            success: function(game, response) {
              var user;
              if (game.deadlineHasPassed()) {
                return res.send(400, {}, "deadlineHasPassed");
              }
              pick.game = game;
              if (!pick.editable()) return res.send(400, {}, "not editable");
              user = new User({
                _id: pick.get("userId")
              });
              return user.getButters({
                error: function(_, response) {
                  return res.send(response.status_code, {}, response);
                },
                success: function(butters) {
                  var butterReclaimed, newButterUsed;
                  user.butters = butters;
                  newButterUsed = params.butter && (!pick.get("butter"));
                  butterReclaimed = pick.get("butter") && (!params.butter);
                  if (newButterUsed && (user.butters <= 0)) {
                    return res.send(400, {}, "insufficient butter");
                  }
                  if (!pick.set(params)) {
                    return res.send(400, {}, "invalid params");
                  }
                  pick.set({
                    updatedDate: new Date()
                  });
                  return pick.save(pick.toJSON(), {
                    error: function(_, response) {
                      return res.send(response.status_code, {}, response);
                    },
                    success: function(pick, response) {
                      var tr;
                      if (!(newButterUsed || butterReclaimed)) {
                        return res.send(pick);
                      }
                      tr = new ButterTransaction({
                        userId: user.id,
                        pickId: pick.id,
                        amount: (newButterUsed ? -1 : 1),
                        createdDate: pick.get("updatedDate")
                      });
                      return tr.save(tr.toJSON(), {
                        error: function(model, response) {
                          return res.send(response.status_code, {}, response);
                        },
                        success: function(model, response) {
                          return res.send(pick);
                        }
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    });
  });

}).call(this);
