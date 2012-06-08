(function() {
  var Game, Period, PeriodUpdateJob, models, util, workers;

  util = require("util");

  models = require("./models");

  Game = models.Game;

  Period = models.Period;

  workers = require("./workers");

  PeriodUpdateJob = workers.PeriodUpdateJob;

  Game.prototype.getCouchId = function() {
    return "game_" + (this.get('statsKey'));
  };

  Game.prototype.initialize = function() {
    if (this.get("statsKey")) {
      if (!this.get("id")) {
        return this.set({
          id: this.getCouchId()
        });
      }
    }
  };

  Game.createOrUpdateGameFromStatsAttributes = function(params, options) {
    var g;
    g = new Game({
      statsKey: params.statsKey
    });
    return g.fetch({
      error: function(game, response) {
        if (response.status_code !== 404) return options.error(game, response);
        return game.updateFromStatsAttributes(params, options);
      },
      success: function(game, response) {
        return game.updateFromStatsAttributes(params, options);
      }
    });
  };

  Game.prototype.updateFromStatsAttributes = function(params, options) {
    var attributes, oldBasePeriodId,
      _this = this;
    oldBasePeriodId = this.basePeriodId();
    attributes = Game.attrFromStatServerParams(params);
    return this.save(attributes, {
      error: options.error,
      success: function(game, gameCouchResponse) {
        var periodUpdateJobParams;
        console.log("FIXME assumption of daily category in PeriodUpdateJob creation");
        periodUpdateJobParams = {
          periodId: game.basePeriodId(),
          league: game.get("league"),
          category: "daily",
          withinDate: game.get("startDate")
        };
        return PeriodUpdateJob.create(periodUpdateJobParams, {
          error: options.error,
          success: function() {
            if (!(oldBasePeriodId && oldBasePeriodId !== game.basePeriodId())) {
              return options.success(game, gameCouchResponse);
            }
            return PeriodUpdateJob.create({
              periodId: oldBasePeriodId
            }, {
              error: options.error,
              success: function() {
                return options.success(game, gameCouchResponse);
              }
            });
          }
        });
      }
    });
  };

  Game.attrFromStatServerParams = function(params) {
    var attributes;
    return attributes = {
      statsKey: params.statsKey,
      statsLatestUpdateDate: new Date(params.updated_at * 1000),
      league: {
        abbreviation: params.league,
        statsKey: params.leagueStatsKey
      },
      awayTeam: {
        statsKey: params.away_team.key,
        location: params.away_team.location,
        name: params.away_team.name
      },
      homeTeam: {
        statsKey: params.home_team.key,
        location: params.home_team.location,
        name: params.home_team.name
      },
      startDate: new Date(params.starts_at * 1000),
      status: {
        score: {
          away: params.away_score,
          home: params.home_score
        },
        text: params.status,
        final: params.final
      },
      legit: params.legit
    };
  };

  Game.prototype.basePeriodId = function() {
    if (!(this.get("leagueStatsKey") && this.get(startDate))) return null;
    console.log("FIXME assumption of daily category for basePeriodId");
    return Period.getCouchId({
      leagueStatsKey: this.get("leagueStatsKey"),
      category: "daily",
      date: this.get("startDate")
    });
  };

  Period.getCouchId = function(params) {
    var d, dateString, periodId;
    switch (params.category) {
      case "daily":
        d = new Date(params.date);
        dateString = "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
        periodId = "" + params.leagueStatsKey + "_" + params.category + "_" + dateString;
        break;
      case "lifetime":
        periodId = "" + params.leagueStatsKey + "_" + params.category;
    }
    return periodId;
  };

  Period.getOrCreateBasePeriodForGame = function(game, options) {
    var basePeriod, basePeriodId;
    basePeriodId = game.basePeriodId();
    basePeriod = new Period({
      id: periodId
    });
    return p.fetch({
      success: function(p, response) {
        return options.success(p, response);
      },
      error: function(p, response) {
        var data, endDate, gameDate, startDate;
        console.log("FIXME confirm that error comes from absent model: " + (util.inspect(response)));
        console.log("+++ creating " + p.id);
        gameDate = game.get("startDate");
        startDate = new Date(gameDate.getFullYear(), gameDate.getMonth(), gameDate.getDate());
        endDate = (new Date(startDate)).add({
          days: 1
        });
        console.log("FIXME assumption of daily period");
        console.log("FIXME adjust endDate depending on category of period");
        data = {
          league: {
            abbreviation: game.get("league").abbreviation,
            statsKey: game.get("league").statsKey
          },
          category: "daily",
          startDate: startDate,
          endDate: endDate
        };
        return p.save(data, options);
      }
    });
  };

  Period.prototype.fetchGames = function() {
    return console.log("TODO use couchdb view");
  };

}).call(this);
