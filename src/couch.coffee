couch = exports

couchUrl = process.env.CLOUDANT_URL or "http://localhost:5984"
dbName = process.env.CLOUDANT_DB or process.env.testingDbName or 'picks'
couch.db = require("nano")(couchUrl).use dbName
console.log "couch: using '%s' database",dbName


couch.designDocs = 
  facebookObjects:
    views:
      allByFacebookId:
        map: "function (doc) { if (doc.facebookId) emit(doc.facebookId); }"

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

  