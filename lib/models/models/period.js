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

    Period.prototype.defaults = {
      doctype: "Period",
      leagueId: null,
      category: null,
      startDate: null,
      endDate: null
    };

    Period.prototype.validate = function(attr) {
      if (!attr.leagueId) return "no leagueId attribute";
      if (!attr.category) return "no category attribute";
      if (!attr.startDate) return "no startDate attribute";
      if (!attr.endDate) return "no endDate attribute";
    };

    return Period;

  })(Backbone.Model);

}).call(this);
