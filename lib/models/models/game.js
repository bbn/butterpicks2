(function() {
  var Backbone, Game,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = Game = (function(_super) {

    __extends(Game, _super);

    function Game() {
      Game.__super__.constructor.apply(this, arguments);
    }

    Game.prototype.idAttribute = "_id";

    Game.prototype.defaults = {
      doctype: "Game",
      statsKey: null,
      statsLatestUpdateDate: null,
      league: {
        statsKey: null,
        abbreviation: null
      },
      awayTeam: {
        statsKey: null,
        name: null
      },
      homeTeam: {
        statsKey: null,
        name: null
      },
      startDate: null,
      status: {
        score: {
          away: null,
          home: null
        },
        text: null,
        final: null,
        legit: null,
        postponed: null
      },
      pickCount: {
        home: null,
        away: null,
        draw: null
      },
      basePeriodKey: null
    };

    Game.prototype.secondsUntilDeadline = function() {
      var now, start;
      start = this.get("startDate");
      now = new Date();
      return start - now;
    };

    return Game;

  })(Backbone.Model);

}).call(this);
