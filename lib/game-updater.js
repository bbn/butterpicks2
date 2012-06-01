
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
          var count, gameData, requestOptions, _i, _len, _results;
          if (error) {
            return console.log("!! error get api/getgamesrecentlyupdated: " + (util.inspect(error)));
          }
          count = body.length;
          console.log("+++ " + count + " games to update.");
          _results = [];
          for (_i = 0, _len = body.length; _i < _len; _i++) {
            gameData = body[_i];
            gameData.statsKey = gameData.key;
            requestOptions = {
              url: "http://localhost/game",
              body: JSON.stringify(gameData),
              json: true
            };
            _results.push(request.post(requestOptions, function(err, clientResponse, body) {
              console.log("err: " + err);
              console.log("body: " + body);
              if (options && options.poll) if (!--count) return poll();
            }));
          }
          return _results;
        });
      }
    });
  };

}).call(this);
