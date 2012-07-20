(function() {
  var Backbone, Game, Job, Period, User, UserPeriod, UserPeriodUpdateJob, couch, models, util, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Job = require("./job");

  _ = require("underscore");

  util = require("util");

  require("../../date");

  Backbone = require("backbone");

  couch = require("../../couch");

  models = require("../../models");

  Period = models.Period;

  Game = models.Game;

  User = models.User;

  UserPeriod = models.UserPeriod;

  module.exports = UserPeriodUpdateJob = (function(_super) {

    __extends(UserPeriodUpdateJob, _super);

    function UserPeriodUpdateJob() {
      UserPeriodUpdateJob.__super__.constructor.apply(this, arguments);
    }

    UserPeriodUpdateJob.prototype.idAttribute = "_id";

    UserPeriodUpdateJob.prototype.defaults = {
      job: true,
      doctype: "UserPeriodUpdateJob",
      createdDate: new Date(),
      userPeriodId: null
    };

    UserPeriodUpdateJob.prototype.work = function(options) {
      var _this = this;
      this.userPeriod = new UserPeriod({
        id: this.get("userPeriodId")
      });
      return this.userPeriod.fetch({
        error: options.error,
        success: function(userPeriod) {
          return _this.userPeriod.fetchPeriod({
            error: function(__, response) {
              if (response.status_code !== 404) return options.error(response);
              return _this.userPeriod.destroy({
                error: options.error,
                success: function() {
                  return options.success(_this);
                }
              });
            },
            success: function(period) {
              _this.period = period;
              return _this.updatePoints({
                error: options.error,
                success: function() {
                  if (!_this.period.get("final")) return options.success(_this);
                  return _this.updatePrizes({
                    error: options.error,
                    success: function() {
                      return options.success(_this);
                    }
                  });
                }
              });
            }
          });
        }
      });
    };

    UserPeriodUpdateJob.prototype.updatePoints = function(options) {
      var _this = this;
      return this.userPeriod.fetchGames({
        error: options.error,
        success: function(games) {
          if (!games.length) {
            return options.error("zero games for period " + _this.period.id);
          }
          _this.userPeriod.games = games;
          return _this.userPeriod.fetchPicks({
            error: options.error,
            success: function(picks) {
              var metrics, pick, points, _i, _len;
              points = 0;
              for (_i = 0, _len = picks.length; _i < _len; _i++) {
                pick = picks[_i];
                points += pick.points();
              }
              metrics = _this.userPeriod.get("metrics");
              if (metrics.points === points) return options.success(_this);
              metrics.points = points;
              return _this.userPeriod.save({
                metrics: metrics
              }, {
                error: options.error,
                success: function(userPeriod) {
                  return options.success(_this);
                }
              });
            }
          });
        }
      });
    };

    UserPeriodUpdateJob.prototype.updatePrizes = function(options) {
      var _this = this;
      return this.userPeriod.determinePrizes({
        error: options.error,
        success: function(prizes) {
          var metrics, prize, _i, _len;
          metrics = _this.userPeriod.get("metrics");
          for (_i = 0, _len = prizes.length; _i < _len; _i++) {
            prize = prizes[_i];
            if (prize.won) {
              metrics[prize.id] = 1;
            } else {
              delete metrics[prize.id];
            }
          }
          return _this.userPeriod.save({
            metrics: metrics
          }, {
            error: options.error,
            success: function(userPeriod) {
              return options.success(_this);
            }
          });
        }
      });
    };

    return UserPeriodUpdateJob;

  })(Job);

}).call(this);
