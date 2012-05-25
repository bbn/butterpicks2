# saving backbone models to couchdb. bbn 2012-05-24

_ = require "underscore"
util = require "util"
couchUrl = process.env.CLOUDANT_URL or "http://localhost:5984"
dbName = process.env.CLOUDANT_DB or process.env.testingDbName or 'picks'
db = require("nano")(couchUrl).use dbName
console.log "bbCouch: using '%s' database",dbName

documentUpdateConflictError = () ->
  err = new Error("Document update conflict.")
  err.reason = "Document update conflict."
  err.statusCode = 409
  return err

exports.sync = (method,model,options) ->
  success = options.success
  error = options.error
  switch method
        
    when "read" 
      error(new Error("no id")) unless model.id
      db.get model.id, (err,body,header) ->
        return error(err) if err 
        return success(body)

    when "update","create" #backbone confuses creates for updates
      if model.get "_rev"
        db.get model.id, (err,body,header) ->
          return error(err) if err
          return error(documentUpdateConflictError()) if body._rev != model.get "_rev"
          newDoc = _(body).extend model.toJSON()
          db.insert newDoc, newDoc.id, (err,body,header) ->
            return error(err) if err
            return success 
              _rev: body.rev
              _id: body.id
              id: body.id
      else
        return db.insert model.toJSON(), (err,body,header) ->
          return error(err) if err
          return success 
            _rev: body.rev
            _id: body.id
            id: body.id
            
    when "delete"
      db.get model.id, (err,body,header) ->
        return error(err) if err
        return error(documentUpdateConflictError()) if body._rev != model.get "_rev"
        db.destroy model.id, model.get("_rev"), (err,body,header) ->
          return error(err) if err
          return success(body)

