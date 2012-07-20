(function() {
  var models;

  models = exports;

  models.User = require("./models/user");

  models.ButterTransaction = require("./models/butter-transaction");

  models.League = require("./models/league");

  models.Game = require("./models/game");

  models.Period = require("./models/period");

  models.Pick = require("./models/pick");

  models.UserPeriod = require("./models/user-period");

  models.Prize = require("./models/prize");

}).call(this);
