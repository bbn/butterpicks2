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
        success: function(userPeriod, response) {
          _this.period = new Period({
            id: _this.userPeriod.get("periodId")
          });
          return _this.period.fetch({
            error: function(model, response) {
              console.log("TODO - instead of deleting, flag periods and user periods as invalid");
              if (response.status_code === 404) {
                return _this.userPeriod.destroy({
                  error: options.error,
                  success: function() {
                    return options.success(_this);
                  }
                });
              }
            },
            success: function(model, response) {
              console.log("TODO process the user period. update points, achivements, etc.");
              return options.success(_this);
            }
          });
        }
      });
    };

    return UserPeriodUpdateJob;

  })(Job);

}).call(this);
