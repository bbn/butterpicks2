(function() {
  var ButterTransaction, Game, League, Period, PeriodUpdateJob, Pick, User, UserPeriod, couch, models, util, workers;

  util = require("util");

  couch = require("./couch");

  models = require("./models");

  User = models.User;

  Game = models.Game;

  League = models.League;

  Period = models.Period;

  UserPeriod = models.UserPeriod;

  Pick = models.Pick;

  ButterTransaction = models.ButterTransaction;

  workers = require("./workers");

  PeriodUpdateJob = workers.PeriodUpdateJob;

  League.fetchForStatsKey = function(statsKey, options) {
    return couch.db.view("leagues", "byStatsKey", {
      key: statsKey,
      include_docs: true
    }, function(err, body, headers) {
      var league;
      if (err) return options.error(null, err);
      if (!body.rows.length) return options.success(null, headers);
      league = new League(body.rows[0].doc);
      return options.success(league);
    });
  };

  User.prototype.getButters = function(options) {
    var viewParams;
    viewParams = {
      group_level: 1,
      startkey: [this.id, '1970-01-01T00:00:00.000Z'],
      endkey: [this.id, '2070-01-01T00:00:00.000Z']
    };
    return couch.db.view("butters", "byUserId", viewParams, function(err, body, headers) {
      var value;
      if (err) return options.error(null, err);
      value = body.rows.length ? body.rows[0].value : null;
      return options.success(value);
    });
  };

  User.prototype.fetchButterTransactions = function(options) {
    var viewParams;
    viewParams = {
      reduce: false,
      startkey: [this.id, '1970-01-01T00:00:00.000Z'],
      endkey: [this.id, '2070-01-01T00:00:00.000Z'],
      include_docs: true
    };
    return couch.db.view("butters", "byUserId", viewParams, function(err, body, headers) {
      var row, trannies;
      if (err) return options.error(null, err);
      if (!body.rows) return options.success([], headers);
      trannies = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new ButterTransaction(row.doc));
        }
        return _results;
      })();
      return options.success(trannies);
    });
  };

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
    var _this = this;
    return League.fetchForStatsKey(params.leagueStatsKey, {
      error: options.error,
      success: function(league, response) {
        if (!league) {
          return options.error(null, "no league for statsKey " + params.leagueStatsKey);
        }
        _this.set({
          leagueId: league.id,
          startDate: new Date(params.starts_at * 1000)
        });
        return _this.fetchBasePeriodId({
          error: options.error,
          success: function(basePeriodId) {
            var attributes, oldBasePeriodId;
            oldBasePeriodId = basePeriodId;
            attributes = Game.attrFromStatServerParams(params);
            attributes.leagueId = league.id;
            return _this.save(attributes, {
              error: options.error,
              success: function(game, gameCouchResponse) {
                return game.fetchBasePeriodId({
                  error: options.error,
                  success: function(newBasePeriodId) {
                    var periodUpdateJobParams;
                    periodUpdateJobParams = {
                      periodId: newBasePeriodId,
                      leagueId: league.id,
                      category: league.basePeriodCategory,
                      withinDate: game.get("startDate")
                    };
                    return PeriodUpdateJob.create(periodUpdateJobParams, {
                      error: options.error,
                      success: function() {
                        if (!(oldBasePeriodId && oldBasePeriodId !== newBasePeriodId)) {
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

  Game.prototype.fetchBasePeriodId = function(options) {
    var league,
      _this = this;
    if (!(this.get("leagueId") && this.get("startDate"))) {
      return options.error(null, "param error");
    }
    league = new League({
      id: this.get("leagueId")
    });
    return league.fetch({
      error: options.error,
      success: function(league, response) {
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

  Period.getCouchId = function(params) {
    var d, dateString, periodId;
    switch (params.category) {
      case "daily":
        d = new Date(params.date);
        dateString = "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
        periodId = "" + params.leagueId + "_" + params.category + "_" + dateString;
        break;
      case "lifetime":
        periodId = "" + params.leagueId + "_" + params.category;
    }
    return periodId;
  };

  Period.getOrCreateBasePeriodForGame = function(game, options) {
    return game.fetchBasePeriodId({
      error: options.error,
      success: function(basePeriodId) {
        var p;
        p = new Period({
          id: basePeriodId
        });
        return p.fetch({
          success: options.success,
          error: function(p, response) {
            var league;
            console.log("FIXME confirm that error comes from absent model: " + (util.inspect(response)));
            league = new League({
              id: game.get("leagueId")
            });
            return league.fetch({
              error: options.error,
              success: function(league, response) {
                var data, endDate, gameDate, startDate;
                gameDate = game.get("startDate");
                switch (league.get("basePeriodCategory")) {
                  case "daily":
                    startDate = new Date(gameDate.getFullYear(), gameDate.getMonth(), gameDate.getDate());
                    endDate = (new Date(startDate)).add({
                      days: 1
                    });
                    break;
                  case "weekly":
                    console.log("FIXME no code in place for weekly categories");
                    console.log("FIXME adjust endDate depending on category of period");
                }
                data = {
                  leagueId: game.get("leagueId"),
                  category: league.get("basePeriodCategory"),
                  startDate: startDate,
                  endDate: endDate
                };
                return p.save(data, options);
              }
            });
          }
        });
      }
    });
  };

  Period.prototype.fetchGames = function(options) {
    var viewParams;
    viewParams = {
      startkey: [this.get("leagueId"), this.get("startDate").toJSON()],
      endkey: [this.get("leagueId"), this.get("endDate").toJSON()],
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
      descending: true,
      startkey: [this.id, 99999999999],
      endkey: [this.id, -99999999999],
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
          leagueId: p.get("leagueId"),
          periodStartDate: p.get("startDate"),
          periodCategory: p.get("category"),
          userId: params.userId
        });
        return userPeriod.save(userPeriod.toJSON(), options);
      }
    });
  };

  UserPeriod.fetchForPeriod = function(params, options) {
    var high, low, viewParams;
    high = [params.periodId, 999999999999];
    low = [params.periodId, -999999999999];
    viewParams = {
      descending: (params.descending ? true : false),
      startkey: (params.descending ? high : low),
      endkey: (params.descending ? low : high),
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

  UserPeriod.fetchForUserAndLeague = function(params, options) {
    var viewParams;
    viewParams = {
      startkey: [params.userId, params.leagueId, (new Date(1970, 1, 1)).toJSON()],
      endkey: [params.userId, params.leagueId, (new Date(2070, 1, 1)).toJSON()],
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

  Pick.getCouchId = function(params) {
    if (!(params.userId && params.gameId)) return null;
    return "" + params.userId + "_" + params.gameId;
  };

  Pick.create = function(params, options) {
    var d, pick;
    if (!(params.gameId && params.userId)) {
      return options.error("userId, gameId params plz");
    }
    pick = new Pick(params);
    d = new Date();
    pick.set({
      id: Pick.getCouchId(params),
      createdDate: d,
      updatedDate: d
    });
    return pick.save(pick.toJSON(), options);
  };

  Pick.fetchForUserAndGame = function(params, options) {
    var pick, pickId;
    pickId = Pick.getCouchId(params);
    pick = new Pick({
      id: pickId
    });
    return pick.fetch(options);
  };

}).call(this);
