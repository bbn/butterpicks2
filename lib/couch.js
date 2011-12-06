(function() {
  var cloudant_url, connection, couch, cradle, database_name, gaedocsViews, options, password, port, protocol, stuff, username, _, _ref, _ref2, _ref3;

  cradle = require("cradle");

  _ = require("underscore");

  couch = exports;

  database_name = "picks";

  if (process.env.CLOUDANT_URL) {
    _ref = process.env.CLOUDANT_URL.split('@'), stuff = _ref[0], cloudant_url = _ref[1];
    _ref2 = stuff.split('://'), protocol = _ref2[0], stuff = _ref2[1];
    _ref3 = stuff.split(':'), username = _ref3[0], password = _ref3[1];
    if (protocol === 'https') {
      port = 443;
    } else {
      port = 5984;
    }
    options = {
      cache: false,
      raw: false,
      auth: {
        username: username,
        password: password
      }
    };
    connection = new cradle.Connection("" + protocol + "://" + cloudant_url, port, options);
    couch.db = connection.database(database_name);
  } else {
    cloudant_url = "127.0.0.1";
    port = 5984;
    protocol = 'http';
    connection = new cradle.Connection(cloudant_url, port);
    couch.db = connection.database(database_name);
  }

  console.log("checking for database " + database_name + " on " + protocol + "://" + cloudant_url + ":" + port);

  couch.db.exists(function(err, exists) {
    if (err) {
      return console.log("error", err);
    } else if (exists) {} else {
      console.log("database does not exist. creating...");
      return couch.db.create(function() {
        return console.log("database created!");
      });
    }
  });

  couch.updateDesignDocument = function(path, document, callback) {
    var url;
    url = "_design/" + path;
    return couch.db.get(url, function(err, doc) {
      if (err) {
        if (err.error !== "not_found" || err.reason !== "missing") {
          return callback(err, doc);
        }
      }
      if (doc) {
        document._rev = doc._rev;
        document._id = doc._id;
      }
      return couch.db.save(url, document, function(err, doc) {
        return callback(err, doc);
      });
    });
  };

  gaedocsViews = {
    allByKey: {
      map: function(doc) {
        if (doc.gaekey) return emit(doc.gaekey);
      }
    }
  };

  couch.updateDesignDocument("gaedocs", gaedocsViews, function(err, doc) {
    return console.log("TODO should NOT update design document every time! couchapp.org!!");
  });

}).call(this);
