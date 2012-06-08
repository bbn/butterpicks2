(function() {
  var Backbone, Game, Period, PeriodUpdateJob, couch, models, util, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  _ = require("underscore");

  util = require("util");

  require("../../date");

  Backbone = require("backbone");

  couch = require("../../couch");

  models = require("../../models");

  Period = models.Period;

  Game = models.Game;

  module.exports = PeriodUpdateJob = (function(_super) {

    __extends(PeriodUpdateJob, _super);

    function PeriodUpdateJob() {
      PeriodUpdateJob.__super__.constructor.apply(this, arguments);
    }

    PeriodUpdateJob.doctype = "PeriodUpdateJob";

    PeriodUpdateJob.prototype.idAttribute = "_id";

    PeriodUpdateJob.prototype.defaults = {
      job: true,
      doctype: "PeriodUpdateJob",
      createdDate: new Date(),
      periodId: null,
      league: {
        statsKey: null,
        abbreviation: null
      },
      category: null,
      withinDate: null
    };

    PeriodUpdateJob.prototype.work = function(options) {
      var _this = this;
      return this.fetchOrCreatePeriod({
        error: options.error,
        success: function(period) {
          return options.success(_this);
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
          var category, endDate, league, startDate, withinDate;
          console.log("FIXME: confirm it's missing and not a real error: " + (util.inspect(response)));
          console.log("FIXME: generalize for non-daily periods");
          withinDate = _this.get("withinDate");
          league = _this.get("league");
          category = _this.get("category");
          if (!(withinDate && league && category)) {
            return options.error(model, response);
          }
          startDate = withinDate.clearTime();
          endDate = (new Date(startDate)).addDays(1);
          period.set({
            league: league,
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

    PeriodUpdateJob.create = function(params, options) {
      var j,
        _this = this;
      j = new this;
      return j.save(params, {
        error: options.error,
        success: function(job, response) {
          options.success(job, response);
          if (!_this.workSuspended) return _this.startWorking();
        }
      });
    };

    PeriodUpdateJob.workSuspended = false;

    PeriodUpdateJob.workInProgress = false;

    PeriodUpdateJob.startWorking = function() {
      console.log("@startWorking");
      if (!this.workInProgress) return this.doWork();
    };

    PeriodUpdateJob.doWork = function() {
      var _this = this;
      console.log("@doWork");
      this.workInProgress = true;
      return this.getNext({
        error: function(model, response) {
          console.log("!!! fetching next job error: " + (util.inspect(response)));
          return _this.doWork();
        },
        success: function(model, response) {
          if (!model) return _this.stopWorking();
          return model.work({
            error: function(_, response) {
              console.log("!!! work error: " + (util.inspect(response)));
              return _this.doWork();
            },
            success: function(model) {
              return model.destroy({
                error: function() {
                  console.log("!!! deleting job error: " + (util.inspect(response)));
                  return _this.doWork();
                },
                success: function() {
                  return _this.doWork();
                }
              });
            }
          });
        }
      });
    };

    PeriodUpdateJob.stopWorking = function() {
      console.log("@stopWorking");
      return this.workInProgress = false;
    };

    PeriodUpdateJob.getNext = function(options) {
      var viewParams,
        _this = this;
      viewParams = {
        startkey: [this.doctype, '1970-01-01T00:00:00.000Z'],
        endKey: [this.doctype, '2070-01-01T00:00:00.000Z'],
        include_docs: true,
        limit: options.limit || 1
      };
      return couch.db.view("jobs", "byType", viewParams, function(err, body, headers) {
        var jobs, row;
        if (err) return options.error(null, err);
        jobs = (function() {
          var _i, _len, _ref, _results;
          _ref = body.rows;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            row = _ref[_i];
            _results.push(new this(row.doc));
          }
          return _results;
        }).call(_this);
        if (viewParams.limit === 1) jobs = jobs[0];
        return options.success(jobs, headers);
      });
    };

    return PeriodUpdateJob;

  })(Backbone.Model);

}).call(this);
