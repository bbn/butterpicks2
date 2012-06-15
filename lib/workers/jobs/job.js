(function() {
  var Backbone, Job, couch,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  couch = require("../../couch");

  require("util");

  Backbone = require("backbone");

  module.exports = Job = (function(_super) {

    __extends(Job, _super);

    function Job() {
      Job.__super__.constructor.apply(this, arguments);
    }

    Job.prototype.idAttribute = "_id";

    Job.prototype.defaults = {
      job: true,
      doctype: "Job",
      createdDate: new Date()
    };

    Job.prototype.initialize = function() {
      if (!this.get("job")) {
        this.set({
          job: true
        });
      }
      if (!this.get("createdDate")) {
        this.set({
          createdDate: new Date()
        });
      }
      if (!this.get("doctype")) {
        return console.log("ERROR: need a doctype in defaults!");
      }
    };

    Job.prototype.work = function(options) {
      console.log("FIXME override work method in " + (this.get('doctype')));
      return options.error(this);
    };

    Job.workSuspended = false;

    Job.create = function(params, options) {
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

    Job.workInProgress = false;

    Job.startWorking = function() {
      console.log("@startWorking");
      if (!this.workInProgress) return this.doWork();
    };

    Job.doWork = function() {
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

    Job.stopWorking = function() {
      console.log("@stopWorking");
      return this.workInProgress = false;
    };

    Job.getNext = function(options) {
      var doctype, viewParams,
        _this = this;
      doctype = this.prototype.defaults.doctype;
      viewParams = {
        startkey: [doctype, '1970-01-01T00:00:00.000Z'],
        endKey: [doctype, '2070-01-01T00:00:00.000Z'],
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

    return Job;

  })(Backbone.Model);

}).call(this);
