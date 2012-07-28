(function() {
  var Backbone, Period,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = Period = (function(_super) {

    __extends(Period, _super);

    function Period() {
      Period.__super__.constructor.apply(this, arguments);
    }

    Period.prototype.idAttribute = "_id";

    Period.prototype.defaults = {
      doctype: "Period",
      leagueId: null,
      category: null,
      startDate: null,
      endDate: null,
      final: false
    };

    Period.prototype.games = null;

    Period.prototype.userPeriods = null;

    Period.prototype.validate = function(attr) {
      if (!attr.leagueId) return "no leagueId attribute";
      if (!attr.category) return "no category attribute";
      if (!attr.startDate) return "no startDate attribute";
      if (!attr.endDate) return "no endDate attribute";
    };

    Period.prototype.initialize = function(attr) {
      if (!attr._id) {
        return this.set({
          _id: this.constructor.getCouchId(attr)
        });
      }
    };

    Period.getCouchId = function(params) {
      var d, dateString;
      switch (params.category) {
        case "daily":
          d = new Date(params.date || params.startDate);
          dateString = "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
          return "" + params.leagueId + "_" + params.category + "_" + dateString;
        case "lifetime":
          return "" + params.leagueId + "_" + params.category;
      }
    };

    return Period;

  })(Backbone.Model);

}).call(this);
