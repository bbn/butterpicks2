(function() {
  var Game, couch, models;

  couch = require("./couch");

  models = require("./models");

  Game = models.Game;

  exports.getMostRecentlyUpdatedGameDate = function(options) {
    var viewParams;
    viewParams = {
      descending: true,
      limit: 1
    };
    return couch.db.view("games", "mostRecentlyUpdated", viewParams, function(err, body, headers) {
      var d;
      if (err) return options.error(null, err);
      d = body.rows.length ? new Date(JSON.parse(body.rows[0].key)) : null;
      return options.success(d, body);
    });
  };

}).call(this);
