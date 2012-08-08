(function() {
  var Backbone, Game, Job, Period, PeriodUpdateJob, UserPeriodUpdateJob, couch, models, util, _,
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

  UserPeriodUpdateJob = require("./user-period-update-job");

  module.exports = PeriodUpdateJob = (function(_super) {

    __extends(PeriodUpdateJob, _super);

    function PeriodUpdateJob() {
      PeriodUpdateJob.__super__.constructor.apply(this, arguments);
    }

    PeriodUpdateJob.prototype.idAttribute = "_id";

    PeriodUpdateJob.prototype.defaults = {
      job: true,
      doctype: "PeriodUpdateJob",
      createdDate: new Date(),
      periodId: null,
      gameId: null
    };

    PeriodUpdateJob.prototype.work = function(options) {
      var _this = this;
      return this.fetchOrCreatePeriod({
        error: options.error,
        success: function(period) {
          _this.period = period;
          return _this.period.fetchGames({
            error: options.error,
            success: function(games) {
              var process;
              process = games.length ? _this.updatePeriod : _this.deletePeriod;
              return process.call(_this, {
                error: options.error,
                success: function() {
                  return options.success(_this);
                }
              });
            }
          });
        }
      });
    };

    PeriodUpdateJob.prototype.deletePeriod = function(options) {
      var _this = this;
      return this.period.destroy({
        error: options.error,
        success: function() {
          return _this.updateUserPeriods({
            error: options.error,
            success: options.success
          });
        }
      });
    };

    PeriodUpdateJob.prototype.updatePeriod = function(options) {
      var _this = this;
      return this.updateFinalStatus({
        error: options.error,
        success: function() {
          console.log("OPTIMIZATION: only updateUserPeriods if results of games have changed significantly");
          return _this.updateUserPeriods({
            error: options.error,
            success: options.success
          });
        }
      });
    };

    PeriodUpdateJob.prototype.updateFinalStatus = function(options) {
      var final, game, _i, _len, _ref;
      final = true;
      _ref = this.period.games;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        game = _ref[_i];
        if (!game.get("status").final) final = false;
      }
      if (!final) return options.success();
      return this.period.save({
        final: true
      }, options);
    };

    PeriodUpdateJob.prototype.updateUserPeriods = function(options) {
      return this.period.fetchUserPeriods({
        error: options.error,
        success: function(userPeriods) {
          var count, errorCalled, userPeriod, _i, _len, _results;
          count = userPeriods.length;
          if (!count) options.success();
          errorCalled = false;
          _results = [];
          for (_i = 0, _len = userPeriods.length; _i < _len; _i++) {
            userPeriod = userPeriods[_i];
            _results.push((function(userPeriod) {
              var job;
              job = new UserPeriodUpdateJob({
                userPeriodId: userPeriod.id
              });
              return job.save(job.toJSON(), {
                success: function() {
                  if (!--count) return options.success();
                },
                error: function(model, response) {
                  if (!errorCalled) {
                    errorCalled = true;
                    return options.error(model, response);
                  }
                }
              });
            })(userPeriod));
          }
          return _results;
        }
      });
    };

    PeriodUpdateJob.prototype.fetchOrCreatePeriod = function(options) {
      var game,
        _this = this;
      if (this.get("periodId")) return this.fetchPeriod(options);
      game = new Game({
        _id: this.get("gameId")
      });
      return game.fetch({
        error: options.error,
        success: function(game) {
          return Period.getOrCreateBasePeriodForGame(game, options);
        }
      });
    };

    PeriodUpdateJob.prototype.fetchPeriod = function(options) {
      var period;
      period = new Period({
        _id: this.get("periodId")
      });
      return period.fetch(options);
    };

    return PeriodUpdateJob;

  })(Job);

}).call(this);
