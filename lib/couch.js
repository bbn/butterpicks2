(function() {
  var couch, design, name, nano;

  couch = exports;

  couch.url = process.env.CLOUDANT_URL || "http://localhost:5984";

  nano = require("nano")(couch.url);

  if (process.env.CLOUDANT_DB) {
    couch.dbname = process.env.CLOUDANT_DB;
  } else if (process.env.testing) {
    couch.dbname = 'picks-testing';
  } else {
    couch.dbname = 'picks';
  }

  couch.db = nano.use(couch.dbname);

  console.log("using '%s' database", couch.dbname);

  couch.designDocs = {
    facebookDocs: {
      views: {
        allByFacebookId: {
          map: "function (doc) { if (doc.facebookId) emit(doc.facebookId); }"
        }
      }
    }
  };

  couch.numberOfDesignDocs = ((function() {
    var _ref, _results;
    _ref = couch.designDocs;
    _results = [];
    for (name in _ref) {
      design = _ref[name];
      _results.push(name);
    }
    return _results;
  })()).length;

  couch.identifyUnmatchedDesignDocs = function(callback) {
    var count, design, error, name, processDesignDoc, unmatched, _ref, _results;
    error = false;
    unmatched = [];
    count = 0;
    processDesignDoc = function(name, design) {
      var url;
      url = "_design/" + name;
      return couch.db.get(url, function(err, body, headers) {
        var details, f, functions, mismatch, s, viewName, _ref;
        mismatch = false;
        if (err && err.error === 'not_found' && err.reason === 'missing') {
          mismatch = true;
        } else if (err) {
          error = true;
          callback(err);
        } else {
          _ref = design.views;
          for (viewName in _ref) {
            functions = _ref[viewName];
            for (f in functions) {
              s = functions[f];
              if (s !== body.views[viewName][f]) mismatch = true;
            }
          }
        }
        if (mismatch) {
          details = {
            name: name,
            design: design,
            old: body
          };
          unmatched.push(details);
        }
        count += 1;
        if (count === couch.numberOfDesignDocs && !error) {
          return callback(null, unmatched);
        }
      });
    };
    _ref = couch.designDocs;
    _results = [];
    for (name in _ref) {
      design = _ref[name];
      _results.push(processDesignDoc(name, design));
    }
    return _results;
  };

  couch.updateDesignDocument = function(path, document, callback) {
    var url;
    url = "_design/" + path;
    return couch.db.get(url, function(err, body, headers) {
      if (err) {
        if (err.error !== "not_found" || err.reason !== "missing") {
          return callback(err, body, headers);
        }
      }
      if (body) {
        document._rev = body._rev;
        document._id = body._id;
      }
      return couch.db.insert(document, url, function(err, body, headers) {
        return callback(err, body, headers);
      });
    });
  };

}).call(this);
