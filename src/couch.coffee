cradle = require "cradle"
_ = require "underscore"

couch = exports

database_name = "picks"

if process.env.CLOUDANT_URL
  [stuff, cloudant_url] = process.env.CLOUDANT_URL.split '@'
  [protocol, stuff] = stuff.split '://'
  [username, password] = stuff.split ':'
  if protocol is 'https'
    port = 443
  else
    port = 5984
  options =
    cache: no
    raw: no
    auth:
      username: username
      password: password
  connection = new(cradle.Connection) "#{protocol}://#{cloudant_url}", port, options
  couch.db = connection.database(database_name)
else
  cloudant_url = "127.0.0.1"
  port = 5984
  protocol = 'http'
  connection = new(cradle.Connection)(cloudant_url, port)
  couch.db = connection.database(database_name)
  
console.log "checking for database #{database_name} on #{protocol}://#{cloudant_url}:#{port}"
couch.db.exists (err,exists) ->
  if err
    console.log "error", err
  else if exists
    #console.log "database exists!"
  else
    console.log "database does not exist. creating..."
    couch.db.create ->
      console.log "database created!"
      
      
couch.updateDesignDocument = (path, document, callback) ->
  url = "_design/"+path
  couch.db.get url, (err,doc) ->
    if err
      if err.error != "not_found" or err.reason != "missing"
        return callback err,doc
    if doc
      document._rev = doc._rev
      document._id = doc._id
    couch.db.save url, document, (err,doc) ->
      return callback err,doc

gaedocsViews = 
  allByKey:
    map: (doc) ->
      if doc.gaekey
        emit doc.gaekey        
couch.updateDesignDocument "gaedocs", gaedocsViews, (err,doc) ->
  console.log "TODO should NOT update design document every time! couchapp.org!!"
  
