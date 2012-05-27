# saving backbone models to couchdb. bbn 2012-05-24

_ = require "underscore"
util = require "util"
couchUrl = process.env.CLOUDANT_URL or "http://localhost:5984"
dbName = process.env.CLOUDANT_DB or process.env.testingDbName or 'picks'
nano = require("nano")(couchUrl)
db = nano.use dbName
console.log "bbCouch: using '%s' database",dbName

documentUpdateConflictError = () ->
  err = new Error("Document update conflict.")
  err.reason = "Document update conflict."
  err.statusCode = 409
  return err

transformAttributesForSaving = (attributes) ->
  (attributes[key] = JSON.stringify(val)) for own key,val of attributes when key.match /Date$/
  return attributes

tranformAttributesFromFetching = (attributes) ->
  (attributes[key] = new Date(JSON.parse(val))) for own key,val of attributes when key.match /Date$/
  return attributes

exports.sync = (method,model,options) ->
  success = options.success
  error = options.error
  switch method
        
    when "read" 
      id = model.id or model.get("id")
      error(new Error("no id")) unless id
      db.get id, (err,body,header) ->
        return error(err) if err
        return success(tranformAttributesFromFetching body)

    when "update","create" #backbone confuses creates for updates
      if model.get "_rev"
        db.get model.id, (err,body,header) ->
          return error(err) if err
          return error(documentUpdateConflictError()) if body._rev != model.get "_rev"
          body = tranformAttributesFromFetching body
          newDoc = _(body).extend model.toJSON()
          newDoc = transformAttributesForSaving newDoc
          db.insert newDoc, newDoc.id, (err,body,header) ->
            return error(err) if err
            return success 
              _rev: body.rev
              _id: body.id
              id: body.id
      else
        attributes = transformAttributesForSaving model.toJSON()
        return db.insert attributes, (err,body,header) ->
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

