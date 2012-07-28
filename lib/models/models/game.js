(function() {
  var Backbone, Game, League, Period,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  League = require("./league");

  Period = require("./period");

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

    Game.prototype.league = null;

    Game.prototype.validate = function(attr) {
      if (attr.doctype !== "Game") return "bad doctype";
      if (!attr.statsKey) return "no statsKey";
      if (!attr.leagueId) return "no leagueId";
      if (!attr.startDate) return "no startDate";
    };

    Game.prototype.initialize = function(attr) {
      if (!this.get("_id")) {
        return this.set({
          _id: this.getCouchId()
        });
      }
    };

    Game.couchIdForStatsKey = function(statsKey) {
      return "game_" + statsKey;
    };

    Game.prototype.getCouchId = function() {
      return this.constructor.couchIdForStatsKey(this.get("statsKey"));
    };

    Game.prototype.fetchLeague = function(options) {
      var _this = this;
      if (this.league) return options.success(this.league);
      return League.fetchById({
        id: this.get("leagueId"),
        error: options.error,
        success: function(league) {
          _this.league = league;
          return options.success(_this.league);
        }
      });
    };

    Game.prototype.fetchBasePeriodId = function(options) {
      var _this = this;
      if (!this.get("leagueId")) return options.error(null, "no leagueId");
      if (!this.get("startDate")) return options.error(null, "no startDate");
      return this.fetchLeague({
        error: options.error,
        success: function(league) {
          var id;
          id = Period.getCouchId({
            leagueId: league.id,
            category: league.get("basePeriodCategory"),
            date: _this.get("startDate")
          });
          return options.success(id);
        }
      });
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
