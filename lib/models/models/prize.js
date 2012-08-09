(function() {
  var Backbone, Prize, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  _ = require("underscore");

  module.exports = Prize = (function(_super) {

    __extends(Prize, _super);

    function Prize() {
      Prize.__super__.constructor.apply(this, arguments);
    }

    Prize.prototype.idAttribute = "_id";

    Prize.prototype.defaults = {
      doctype: "Prize",
      leagueId: null,
      name: null,
      description: null,
      pointValue: null,
      eligibleConditions: null,
      possibleConditions: null,
      successConditions: null,
      failConditions: null
    };

    Prize.prototype.validate = function(attr) {
      var condition, conditions, validOperators, _i, _len;
      if (!attr.leagueId) return "no leagueId";
      if (!(attr.eligibleConditions || attr.possibleConditions || attr.successConditions || attr.failConditions)) {
        return "no conditions";
      }
      conditions = _.flatten(attr.eligibleConditions, attr.possibleConditions, attr.successConditions, attr.failConditions);
      validOperators = [">", ">=", "==", "<", "<="];
      for (_i = 0, _len = conditions.length; _i < _len; _i++) {
        condition = conditions[_i];
        if (!condition.metric) return "no metric for condition " + condition;
        if (!condition.operator) return "no operator for condition " + condition;
        if (!(condition.value || condition.value === 0)) {
          return "no value for condition " + condition;
        }
        if (_(validOperators).indexOf(condition.operator) === -1) {
          return "invalid operator for condition " + condition;
        }
      }
      if (attr.pointValue === null) return "no pointValue";
      if (!attr.name) return "no name";
    };

    Prize.prototype.satisfies = function(metrics, conditions) {
      var condition, _i, _len;
      if (!conditions) return true;
      if (!metrics) return false;
      for (_i = 0, _len = conditions.length; _i < _len; _i++) {
        condition = conditions[_i];
        if (!(metrics[condition.metric] || metrics[condition.metric] === 0)) {
          return false;
        }
        switch (condition.operator) {
          case '>':
            if (!(metrics[condition.metric] > condition.value)) return false;
            break;
          case '>=':
            if (!(metrics[condition.metric] >= condition.value)) return false;
            break;
          case '==':
            if (metrics[condition.metric] !== condition.value) return false;
            break;
          case '<':
            if (!(metrics[condition.metric] < condition.value)) return false;
            break;
          case '<=':
            if (!(metrics[condition.metric] <= condition.value)) return false;
        }
      }
      return true;
    };

    Prize.prototype.eligible = function(metrics) {
      return this.satisfies(metrics, this.get("eligibleConditions"));
    };

    Prize.prototype.possible = function(metrics) {
      return this.eligible(metrics) && (!this.fail(metrics)) && (this.satisfies(metrics, this.get("possibleConditions")));
    };

    Prize.prototype.success = function(metrics) {
      return this.possible(metrics) && this.satisfies(metrics, this.get("successConditions"));
    };

    Prize.prototype.fail = function(metrics) {
      return this.satisfies(metrics, this.get("failConditions"));
    };

    return Prize;

  })(Backbone.Model);

}).call(this);
