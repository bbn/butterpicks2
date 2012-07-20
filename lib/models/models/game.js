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
      leagueId: null,
      awayTeam: {
        statsKey: null,
        location: null,
        name: null
      },
      homeTeam: {
        statsKey: null,
        location: null,
        name: null
      },
      startDate: null,
      status: {
        score: {
          away: null,
          home: null
        },
        text: null,
        final: false
      },
      couldDraw: false,
      legit: true,
      pickCount: {
        home: 0,
        away: 0,
        draw: 0
      }
    };

    Game.prototype.secondsUntilDeadline = function() {
      return (this.get("startDate") - new Date()) / 1000;
    };

    Game.prototype.deadlineHasPassed = function() {
      return this.secondsUntilDeadline() < 0;
    };

    Game.prototype.postponed = function() {
      var status;
      status = this.get("status");
      if (!status.text) return false;
      if (status.text.match(/postponed/)) return true;
      return false;
    };

    Game.prototype.homeWin = function() {
      var status;
      status = this.get("status");
      if (!status.final) return null;
      return status.score.home > status.score.away;
    };

    Game.prototype.awayWin = function() {
      var status;
      status = this.get("status");
      if (!status.final) return null;
      return status.score.away > status.score.home;
    };

    Game.prototype.draw = function() {
      var status;
      if (!this.get("couldDraw")) return null;
      status = this.get("status");
      if (!status.final) return null;
      return status.score.away === status.score.home;
    };

    Game.prototype.final = function() {
      return this.get("status").final;
    };

    return Game;

  })(Backbone.Model);

}).call(this);
