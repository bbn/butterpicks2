(function() {
  var ButterTransaction, Game, League, Period, PeriodUpdateJob, Pick, Prize, User, UserPeriod, couch, models, util, workers;

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

  Prize = models.Prize;

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

  User.prototype.fetchMetrics = function(options) {
    var endDate, leagueId, startDate, viewParams;
    leagueId = options.leagueId || options.league.id;
    startDate = options.startDate ? options.startDate.toJSON() : '1970-01-01T00:00:00.000Z';
    endDate = options.endDate ? options.endDate.toJSON() : '2070-01-01T00:00:00.000Z';
    viewParams = {
      reduce: true,
      startkey: [this.id, leagueId, startDate],
      endkey: [this.id, leagueId, endDate]
    };
    return couch.db.view("userPeriods", "metricsByUserIdAndLeagueIdAndDate", viewParams, function(err, body, headers) {
      if (err) return options.error(null, err);
      if (!body.rows[0]) return options.success({});
      return options.success(body.rows[0].value);
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
    var viewParams,
      _this = this;
    if (this.games) {
      return process.nextTick(function() {
        return options.success(this.games);
      });
    }
    viewParams = {
      startkey: [this.get("leagueId"), this.get("startDate").toJSON()],
      endkey: [this.get("leagueId"), this.get("endDate").toJSON()],
      include_docs: true
    };
    return couch.db.view("games", "byLeagueAndStartDate", viewParams, function(err, body, headers) {
      var row;
      if (err) return options.error(null, err);
      if (!body.rows) return options.success([], headers);
      _this.games = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new Game(row.doc));
        }
        return _results;
      })();
      return options.success(_this.games);
    });
  };

  Period.prototype.fetchUserPeriods = function(options) {
    return UserPeriod.fetchForPeriod({
      periodId: this.id,
      descending: true
    }, options);
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
          userId: params.userId,
          metrics: {
            points: 0
          }
        });
        return userPeriod.save(userPeriod.toJSON(), options);
      }
    });
  };

  UserPeriod.fetchForPeriod = function(params, options) {
    var high, low, viewParams;
    high = [params.periodId, "points", 999999999999];
    low = [params.periodId, "points", -999999999999];
    viewParams = {
      descending: (params.descending ? true : false),
      startkey: (params.descending ? high : low),
      endkey: (params.descending ? low : high),
      include_docs: true
    };
    return couch.db.view("userPeriods", "byPeriodIdAndMetric", viewParams, function(err, body, headers) {
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

  UserPeriod.prototype.fetchPeriod = function(options) {
    var period,
      _this = this;
    if (this.period) {
      return process.nextTick(function() {
        return options.success(this.period);
      });
    }
    period = new Period({
      id: this.get("periodId")
    });
    return period.fetch({
      error: options.error,
      success: function(period) {
        _this.period = period;
        return options.success(_this.period);
      }
    });
  };

  UserPeriod.prototype.fetchGames = function(options) {
    var _this = this;
    if (this.games) {
      return process.nextTick(function() {
        return options.success(this.games);
      });
    }
    return this.fetchPeriod({
      error: options.error,
      success: function(period) {
        return _this.period.fetchGames({
          error: options.error,
          success: function(games) {
            _this.games = games;
            return options.success(_this.games);
          }
        });
      }
    });
  };

  UserPeriod.prototype.fetchPicks = function(options) {
    var _this = this;
    return this.fetchGames({
      error: options.error,
      success: function(games) {
        var errorReturned, game, picks, _i, _len, _ref, _results;
        _this.games = games;
        if (!_this.games.length) return options.success([]);
        picks = [];
        errorReturned = false;
        _ref = _this.games;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          game = _ref[_i];
          _results.push((function(game) {
            return Pick.fetchForUserAndGame({
              userId: _this.get("userId"),
              gameId: game.id
            }, {
              error: function(__, response) {
                if (!errorReturned) options.error(response);
                return errorReturned = true;
              },
              success: function(pick) {
                if (errorReturned) return;
                pick.game = game;
                if (_this.user) pick.user = _this.user;
                picks.push(pick);
                if (picks.length === _this.games.length) {
                  _this.picks = picks;
                  return options.success(_this.picks);
                }
              }
            });
          })(game));
        }
        return _results;
      }
    });
  };

  UserPeriod.prototype.fetchMetrics = function(options) {
    var _this = this;
    return this.fetchPicks({
      error: options.error,
      success: function(picks) {
        var metrics;
        return metrics = {
          picks: _(picks).size(),
          unfinalizedPicks: _(picks).filter(function(pick) {
            return !pick.final();
          }).size(),
          homePicks: _(picks).filter(function(pick) {
            return pick.get("home");
          }).size(),
          awayPicks: _(picks).filter(function(pick) {
            return pick.get("away");
          }).size(),
          drawPicks: _(picks).filter(function(pick) {
            return pick.get("draw");
          }).size(),
          uselessPicks: _(picks).filter(function(pick) {
            return pick.useless();
          }).size() + _this.games.length - _(picks).size(),
          predictions: _(picks).filter(function(pick) {
            return pick.prediction();
          }).size(),
          correctPredictions: _(picks).filter(function(pick) {
            return pick.correctPrediction();
          }).size(),
          incorrectPredictions: _(picks).filter(function(pick) {
            return pick.incorrectPrediction();
          }).size(),
          risks: _(picks).filter(function(pick) {
            return pick.risk();
          }).size(),
          correctRisks: _(picks).filter(function(pick) {
            return pick.correctRisk();
          }).size(),
          incorrectRisks: _(picks).filter(function(pick) {
            return pick.incorrectRisk();
          }).size(),
          safeties: _(picks).filter(function(pick) {
            return pick.safety();
          }).size(),
          butters: _(picks).filter(function(pick) {
            return pick.get("butter");
          }).size(),
          points: _(picks).reduce(function(memo, pick) {
            return memo + pick.points();
          })
        };
      }
    });
  };

  UserPeriod.prototype.determinePrizes = function(options) {
    var _this = this;
    if (!this.user) return options.error("no user loaded");
    if (!this.period) return options.error("no period loaded");
    if (!(options.games || (this.period && this.period.games))) {
      return options.error("no period.games loaded");
    }
    if (!this.picks) return options.error("no picks loaded");
    return Prize.fetchAllForLeague({
      id: this.leagueId
    }, {
      error: options.error,
      success: function(prizes) {
        _this.metrics = {};
        return _this.user.fetchMetrics({
          endDate: _this.periodstartDate,
          leagueId: _this.leagueId,
          error: options.error,
          success: function(userMetrics) {
            _(_this.metrics).extend(userMetrics);
            return _this.period.fetchMetrics({
              error: options.error,
              success: function(periodMetrics) {
                _(_this.metrics).extend(periodMetrics);
                return _this.fetchMetrics({
                  error: options.error,
                  success: function(userPeriodMetrics) {
                    var prize, _i, _len;
                    _(_this.metrics).extend(userPeriodMetrics);
                    for (_i = 0, _len = prizes.length; _i < _len; _i++) {
                      prize = prizes[_i];
                      prize.currentStatus = {
                        eligible: prize.eligible(_this.metrics),
                        possible: prize.possible(_this.metrics),
                        success: prize.success(_this.metrics)
                      };
                    }
                    return options.success(prizes);
                  }
                });
              }
            });
          }
        });
      }
    });
  };

  Prize.fetchAllForLeague = function(league, options) {
    return couch.db.view("prizes", "byLeagueId", {
      key: league.id,
      include_docs: true
    }, function(err, body, headers) {
      var prizes, row;
      if (err) return options.error(null, err);
      if (!body.rows.length) return options.success([], headers);
      prizes = (function() {
        var _i, _len, _ref, _results;
        _ref = body.rows;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          row = _ref[_i];
          _results.push(new Prize(row.doc));
        }
        return _results;
      })();
      return options.success(prizes);
    });
  };

}).call(this);
