(function() {
  var Backbone, League,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = League = (function(_super) {

    __extends(League, _super);

    function League() {
      League.__super__.constructor.apply(this, arguments);
    }

    League.prototype.idAttribute = "_id";

    League.prototype.defaults = {
      doctype: "League",
      statsKey: null,
      imageUrl: null,
      abbreviation: null,
      name: null,
      draws: false,
      basePeriodCategory: null
    };

    return League;

  })(Backbone.Model);

}).call(this);
