(function() {
  var Game, Period, PeriodUpdateJob, User, UserPeriod, couch, models, util, workers;

  util = require("util");

  couch = require("./couch");

  models = require("./models");

  User = models.User;

  Game = models.Game;

  Period = models.Period;

  UserPeriod = models.UserPeriod;

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
      success: options.success,
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

  Period.prototype.fetchGames = function(options) {
    var viewParams;
    viewParams = {
      startkey: [this.get("league").statsKey, this.get("startDate").toJSON()],
      endkey: [this.get("league").statsKey, this.get("endDate").toJSON()],
      include_docs: true
    };
    return couch.db.view("games", "byLeagueAndStartDate", viewParams, function(err, body, headers) {
      var games, row;
      if (err) return options.error(null, err);
      if (!body.rows) return options.success([], headers);
      games = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new Game(row.doc));
        }
        return _results;
      })();
      return options.success(games);
    });
  };

  Period.prototype.fetchUserPeriods = function(options) {
    var viewParams;
    viewParams = {
      startkey: [this.id, -99999999999],
      endkey: [this.id, 99999999999],
      include_docs: true
    };
    return couch.db.view("userPeriods", "byPeriodIdAndPoints", viewParams, function(err, body, headers) {
      var row, userPeriods;
      if (err) return options.error(null, err);
      if (!body.rows) return options.success([], headers);
      userPeriods = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new UserPeriod(row.doc));
        }
        return _results;
      })();
      return options.success(userPeriods);
    });
  };

  UserPeriod.getCouchId = function(params) {
    return "" + params.userId + "_" + params.periodId;
  };

  UserPeriod.fetchForUserAndPeriod = function(params, options) {
    var userPeriod, userPeriodId;
    userPeriodId = UserPeriod.getCouchId(params);
    userPeriod = new UserPeriod({
      id: userPeriodId
    });
    return userPeriod.fetch(options);
  };

  UserPeriod.createForUserAndPeriod = function(params, options) {
    var p, userPeriodId;
    userPeriodId = UserPeriod.getCouchId(params);
    p = new Period({
      id: params.periodId
    });
    return p.fetch({
      error: options.error,
      success: function(p, response) {
        var userPeriod;
        userPeriod = new UserPeriod({
          id: userPeriodId,
          periodId: p.id,
          leagueStatsKey: p.get("league").statsKey,
          periodStartDate: p.get("startDate"),
          periodCategory: p.get("category"),
          userId: params.userId
        });
        return userPeriod.save(userPeriod.toJSON(), options);
      }
    });
  };

  UserPeriod.fetchForPeriod = function(params, options) {
    var p;
    p = new Period({
      id: params.periodId
    });
    return p.fetch({
      error: options.error,
      success: function(p, response) {
        return p.fetchUserPeriods(options);
      }
    });
  };

  UserPeriod.fetchForUserAndLeague = function(params, options) {
    var viewParams;
    viewParams = {
      startkey: [params.userId, params.leagueStatsKey, (new Date(1970, 1, 1)).toJSON()],
      endkey: [params.userId, params.leagueStatsKey, (new Date(2070, 1, 1)).toJSON()],
      include_docs: true
    };
    return couch.db.view("userPeriods", "byUserIdAndLeagueAndDate", viewParams, function(err, body, headers) {
      var row, userPeriods;
      if (err) return options.error(null, err);
      if (!body.rows) return options.success([], headers);
      userPeriods = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new UserPeriod(row.doc));
        }
        return _results;
      })();
      return options.success(userPeriods);
    });
  };

}).call(this);
