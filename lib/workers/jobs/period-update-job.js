(function() {
  var Backbone, PeriodUpdateJob, couch, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  _ = require("underscore");

  Backbone = require("backbone");

  couch = require("../../couch");

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

    PeriodUpdateJob.create = function(params, options) {
      var j,
        _this = this;
      j = new this;
      return j.save(params, {
        error: options.error,
        success: function(job, response) {
          process.nextTick(_this.startWorker);
          return options.success(job, response);
        }
      });
    };

    PeriodUpdateJob.startWorker = function() {
      return console.log("TODO @startWorker");
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
        var jobs, row, _i, _len, _ref;
        if (err) return options.error(null, err);
        _ref = body.rows;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          jobs = new _this(row.doc);
        }
        if (options.limit && !_(jobs).isArray()) jobs = [jobs];
        return options.success(jobs, headers);
      });
    };

    return PeriodUpdateJob;

  })(Backbone.Model);

}).call(this);
