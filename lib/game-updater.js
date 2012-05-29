(function() {
  var Game, couch, getMostRecentlyUpdatedGameDate, models, request, updateGames, util;

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

  updateGames = function() {
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
          return console.log("returned body! " + body);
        });
      }
    });
  };

}).call(this);
