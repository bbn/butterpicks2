
/*
TODO
stats server should ping this app directly when a change is made.
refactor this code so that it accepts updated game data in a request.
*/

(function() {
  var Game, couch, getMostRecentlyUpdatedGameDate, models, poll, pollInterval, request, updateGames, util;

  util = require("util");

  request = require("request");

  couch = require("./couch");

  models = require("./models");

  Game = models.Game;

  exports.getMostRecentlyUpdatedGameDate = getMostRecentlyUpdatedGameDate = function(options) {
    var viewParams;
    viewParams = {
      descending: true,
      limit: 1
    };
    return couch.db.view("games", "mostRecentlyUpdated", viewParams, function(err, body, headers) {
      var date;
      if (err) return options.error(null, err);
      date = body.rows.length ? new Date(body.rows[0].key) : null;
      return options.success(date, body);
    });
  };

  pollInterval = null;

  exports.poll = poll = function(interval) {
    if (interval) pollInterval = interval;
    if (pollInterval) {
      return setTimeout((function() {
        return updateGames({
          poll: true
        });
      }), pollInterval);
    }
  };

  updateGames = function(options) {
    return getMostRecentlyUpdatedGameDate({
      error: function(_, error) {
        return console.log("!! error in getMostRecentlyUpdatedGameDate: " + (util.inspect(error)));
      },
      success: function(lastUpdatedGameDate, response) {
        var integerDate, requestParams, statsUrl;
        integerDate = lastUpdatedGameDate ? parseInt(lastUpdatedGameDate.valueOf() / 1000) : 0;
        statsUrl = "http://butterstats.appspot.com/api/getgamesrecentlyupdated?since=" + integerDate;
        console.log("+++ fetching " + statsUrl);
        requestParams = {
          uri: statsUrl,
          json: true
        };
        return request.get(requestParams, function(error, response, body) {
          var count, gameData, periodsToUpdate, _i, _len, _results;
          if (error) {
            return console.log("!! error get api/getgamesrecentlyupdated: " + (util.inspect(error)));
          }
          count = body.length;
          console.log("+++ " + count + " games to update.");
          periodsToUpdate = [];
          _results = [];
          for (_i = 0, _len = body.length; _i < _len; _i++) {
            gameData = body[_i];
            _results.push((function(gameData) {
              var g, updateGame;
              g = new Game({
                statsKey: gameData.key,
                id: "game_" + gameData.key
              });
              g.fetch({
                error: function(model, response) {
                  console.log("+++ creating " + model.id);
                  return updateGame(model);
                },
                success: function(model, response) {
                  console.log("+++ updating " + model.id);
                  return updateGame(model);
                }
              });
              return updateGame = function(model) {
                var newAttributes;
                newAttributes = {
                  statsKey: gameData.key,
                  statsLatestUpdateDate: new Date(gameData.updated_at * 1000),
                  league: {
                    abbreviation: gameData.league,
                    statsKey: gameData.leagueStatsKey
                  },
                  awayTeam: {
                    statsKey: gameData.away_team.key,
                    location: gameData.away_team.location,
                    name: gameData.away_team.name
                  },
                  homeTeam: {
                    statsKey: gameData.home_team.key,
                    location: gameData.home_team.location,
                    name: gameData.home_team.name
                  },
                  startDate: new Date(gameData.starts_at * 1000),
                  status: {
                    score: {
                      away: gameData.away_score,
                      home: gameData.home_score
                    },
                    text: gameData.status,
                    final: gameData.final,
                    legit: gameData.legit
                  }
                };
                return g.save(newAttributes, {
                  error: function(model, response) {
                    return console.log("!!! error saving game: " + (util.inspect(response)));
                  },
                  success: function(model, response) {
                    count--;
                    if (count === 0) if (options && options.poll) return poll();
                  }
                });
              };
            })(gameData));
          }
          return _results;
        });
      }
    });
  };

}).call(this);
