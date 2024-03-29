(function() {
  var couch, couchUrl, dbName, design, name;

  couch = exports;

  couchUrl = process.env.CLOUDANT_URL || "http://localhost:5984";

  dbName = process.env.CLOUDANT_DB || process.env.testingDbName || 'picks';

  couch.db = require("nano")(couchUrl).use(dbName);

  console.log("couch: using '%s' database", dbName);

  couch.designDocs = {
    leagues: {
      views: {
        byStatsKey: {
          map: "function (doc) { if (doc.doctype=='League') emit(doc.statsKey); }"
        }
      }
    },
    facebookObjects: {
      views: {
        allByFacebookId: {
          map: "function (doc) { if (doc.facebookId) emit(doc.facebookId); }"
        }
      }
    },
    butters: {
      views: {
        byUserId: {
          map: "function (doc) { if (doc.doctype=='ButterTransaction') emit([doc.userId, doc.createdDate], doc.amount); }",
          reduce: "_sum"
        },
        byDate: {
          map: "function (doc) { if (doc.doctype=='ButterTransaction') emit(doc.createdDate, doc.amount); }",
          reduce: "_sum"
        }
      }
    },
    games: {
      views: {
        mostRecentlyUpdated: {
          map: "function (doc) { if (doc.doctype=='Game') emit(doc.statsLatestUpdateDate, null); }"
        },
        byLeagueAndStartDate: {
          map: "function (doc) { if (doc.doctype=='Game') emit([doc.leagueId,doc.startDate], null);  }"
        }
      }
    },
    periods: {
      views: {
        byLeagueCategoryAndDates: {
          map: "function (doc) { if (doc.doctype=='Period') emit([doc.leagueId,doc.category,doc.startDate,doc.endDate],null); }"
        }
      }
    },
    userPeriods: {
      views: {
        byPeriodIdAndMetric: {
          map: "function (doc) {                 if (doc.doctype=='UserPeriod') {                  if (doc.metrics) {                    for (var k in doc.metrics) {                      emit([doc.periodId,k,doc.metrics[k]],null);                    }                                      }                }              }"
        },
        byUserIdAndLeagueAndDate: {
          map: "function (doc) { if (doc.doctype=='UserPeriod') emit([doc.userId,doc.leagueId,doc.periodStartDate],null); }"
        },
        metricsByUserIdAndLeagueIdAndDate: {
          map: "function (doc) {                if (doc.doctype=='UserPeriod') {                  if (doc.metrics) {                    emit([doc.userId,doc.leagueId,doc.periodStartDate], doc.metrics);                  }                }              }",
          reduce: "function (keys,values,rereduce) {                  sumOfMetrics = {};                  for (var i=0;i<values.length;i++) {                    var metrics = values[i];                    for (var k in metrics) {                      if (!sumOfMetrics[k]) {                        sumOfMetrics[k] = 0;                      }                      sumOfMetrics[k] += metrics[k];                    }                  }                  return sumOfMetrics;                }"
        }
      }
    },
    jobs: {
      views: {
        byType: {
          map: "function (doc) { if (doc.job) emit([doc.doctype,doc.createdDate],null); }"
        },
        byDate: {
          map: "function (doc) { if (doc.job) emit([doc.createdDate,doc.doctype],null); }"
        }
      }
    },
    prizes: {
      views: {
        byLeagueId: {
          map: "function (doc) { if (doc.doctype=='Prize') emit(doc.leagueId,null); }"
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
