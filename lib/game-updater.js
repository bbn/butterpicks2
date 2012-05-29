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
      date = body.rows.length ? new Date(JSON.parse(body.rows[0].key)) : null;
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
        integerDate = parseInt(lastUpdatedGameDate.valueOf() / 1000);
        statsUrl = "http://butterstats.appspot.com/api/getgamesrecentlyupdated?since=" + integerDate;
        console.log("+++ fetching " + statsUrl);
        requestParams = {
          uri: statsUrl,
          json: true
        };
        return request.get(requestParams, function(error, response, body) {
          console.log("returned body! " + body);
          if (options && options.poll) return poll();
        });
      }
    });
  };

}).call(this);
