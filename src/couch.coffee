couch = exports

couchUrl = process.env.CLOUDANT_URL or "http://localhost:5984"
dbName = process.env.CLOUDANT_DB or process.env.testingDbName or 'picks'
couch.db = require("nano")(couchUrl).use dbName
console.log "couch: using '%s' database",dbName


couch.designDocs = 
  leagues:
    views:
      byStatsKey:
        map: "function (doc) { if (doc.doctype=='League') emit(doc.statsKey); }"
  facebookObjects:
    views:
      allByFacebookId:
        map: "function (doc) { if (doc.facebookId) emit(doc.facebookId); }"
  butters:
    views:
      byUserId:
        map: "function (doc) { if (doc.doctype=='ButterTransaction') emit([doc.userId, doc.createdDate], doc.amount); }"
        reduce: "_sum"
      byDate:
        map: "function (doc) { if (doc.doctype=='ButterTransaction') emit(doc.createdDate, doc.amount); }"
        reduce: "_sum"
  games:
    views:
      mostRecentlyUpdated:
        map: "function (doc) { if (doc.doctype=='Game') emit(doc.statsLatestUpdateDate, null); }"
      byLeagueAndStartDate:
        map: "function (doc) { if (doc.doctype=='Game') emit([doc.leagueId,doc.startDate], null);  }"
  periods:
    views:
      byLeagueCategoryAndDates:
        map: "function (doc) { if (doc.doctype=='Period') emit([doc.leagueId,doc.category,doc.startDate,doc.endDate],null); }"
  userPeriods:
    views:
      byPeriodIdAndMetric:
        map: "function (doc) { 
                if (doc.doctype=='UserPeriod') {
                  if (doc.metrics) {
                    for (var k in doc.metrics) {
                      emit([doc.periodId,k,doc.metrics[k]],null);
                    }                    
                  }
                }
              }"
      byUserIdAndLeagueAndDate:
        map: "function (doc) { if (doc.doctype=='UserPeriod') emit([doc.userId,doc.leagueId,doc.periodStartDate],null); }"
      metricsByUserIdAndLeagueIdAndDate:
        map: "function (doc) {
                if (doc.doctype=='UserPeriod') {
                  if (doc.metrics) {
                    emit([doc.userId,doc.leagueId,doc.periodStartDate], doc.metrics);
                  }
                }
              }"
        reduce: "function (keys,values,rereduce) {
                  sumOfMetrics = {};
                  for (var i=0;i<values.length;i++) {
                    var metrics = values[i];
                    for (var k in metrics) {
                      if (!sumOfMetrics[k]) {
                        sumOfMetrics[k] = 0;
                      }
                      sumOfMetrics[k] += metrics[k];
                    }
                  }
                  return sumOfMetrics;
                }"

  jobs:
    views:
      byType:
        map: "function (doc) { if (doc.job) emit([doc.doctype,doc.createdDate],null); }"
      byDate:
        map: "function (doc) { if (doc.job) emit([doc.createdDate,doc.doctype],null); }"
  prizes:
    views:
      byLeagueId:
        map: "function (doc) { if (doc.doctype=='Prize') emit(doc.leagueId,null); }"

couch.numberOfDesignDocs = (name for name,design of couch.designDocs).length  


couch.identifyUnmatchedDesignDocs = (callback) ->
  error = false
  unmatched = []
  count = 0
  
  processDesignDoc = (name,design) ->
    url = "_design/"+name
    couch.db.get url, (err,body,headers) ->
      mismatch = false
      if err and err.error == 'not_found' and err.reason == 'missing'
        mismatch = true
      else if err
        error = true
        callback err
      else
        for viewName,functions of design.views
          for f,s of functions
            if s != body.views[viewName][f]
              mismatch = true
      if mismatch
        details = 
          name: name
          design: design
          old: body
        unmatched.push details
      count += 1
      if count == couch.numberOfDesignDocs and !error
        callback null,unmatched
  
  processDesignDoc name,design for name,design of couch.designDocs
  

couch.updateDesignDocument = (path, document, callback) ->
  url = "_design/"+path
  couch.db.get url, (err,body,headers) ->
    if err
      if err.error != "not_found" or err.reason != "missing"
        return callback err,body,headers
    if body
      document._rev = body._rev
      document._id = body._id
    couch.db.insert document, url, (err,body,headers) ->
      callback err,body,headers

  