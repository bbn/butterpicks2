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
      leagueId: null,
      category: null,
      withinDate: null
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
              _this.games = games;
              process = _this.games ? _this.updatePeriod : _this.deletePeriod;
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
      console.log("TODO: only updateUserPeriods if results of games have changed significantly");
      return this.updateUserPeriods({
        error: options.error,
        success: options.success
      });
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
      var period,
        _this = this;
      period = new Period({
        id: this.get("periodId")
      });
      return period.fetch({
        success: options.success,
        error: function(model, response) {
          var category, endDate, leagueId, startDate, withinDate;
          console.log("FIXME: confirm it's missing and not a real error: " + (util.inspect(response)));
          console.log("FIXME: generalize for non-daily periods");
          withinDate = _this.get("withinDate");
          leagueId = _this.get("leagueId");
          category = _this.get("category");
          if (!(withinDate && leagueId && category)) {
            return options.error(model, response);
          }
          startDate = withinDate.clearTime();
          endDate = (new Date(startDate)).addDays(1);
          period.set({
            leagueId: leagueId,
            category: category,
            startDate: startDate,
            endDate: endDate
          });
          return period.save(period.toJSON(), {
            error: function(model, response) {
              return options.error(model, response);
            },
            success: function(model, response) {
              return options.success(model, response);
            }
          });
        }
      });
    };

    return PeriodUpdateJob;

  })(Job);

}).call(this);
