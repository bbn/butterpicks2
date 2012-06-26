(function() {
  var Backbone, Prize,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = Prize = (function(_super) {

    __extends(Prize, _super);

    function Prize() {
      Prize.__super__.constructor.apply(this, arguments);
    }

    Prize.prototype.defaults = {
      doctype: "Prize",
      name: null,
      pointValue: null,
      rule: "function (results) { return false; }",
      prerequisities: []
    };

    Prize.prototype.validate = function(attr) {
      if (!attr.rule) return "no rule attribute";
      if (attr.pointValue === null) return "no pointValue";
      if (!attr.name) return "no name";
    };

    return Prize;

  })(Backbone.Model);

}).call(this);
