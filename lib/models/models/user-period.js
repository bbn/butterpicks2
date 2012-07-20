(function() {
  var Backbone, UserPeriod,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = UserPeriod = (function(_super) {

    __extends(UserPeriod, _super);

    function UserPeriod() {
      UserPeriod.__super__.constructor.apply(this, arguments);
    }

    UserPeriod.prototype.defaults = {
      doctype: "UserPeriod",
      userId: null,
      periodId: null,
      periodStartDate: null,
      periodCategory: null,
      leagueId: null,
      metrics: {}
    };

    UserPeriod.prototype.user = null;

    UserPeriod.prototype.period = null;

    return UserPeriod;

  })(Backbone.Model);

}).call(this);
