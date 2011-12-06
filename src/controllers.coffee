couch = require "./couch"

journey = require "journey"

controllers = exports
controllers.router = new journey.Router
controllers.router.map ->
  
  @root.bind (req,res) ->
    res.send "welcome"
  
  @post("/from-gae/couchmodel-put").bind (req,res,params) ->
    if not params.gaekey
      console.log "no gaekey"
      return res.send 403,{},{error:"no gaekey"}
    if not params.doctype
      return res.send 403,{},{error:"no doctype"}

    console.log "/from-gae/couchmodel-put: "+params.doctype      
    res.send 202,{},params
        
    couch.db.view "gaedocs/allByKey", { key: params.gaekey, include_docs: true }, (err, data) ->
      if data and data.length > 0
        params._rev = data[0].doc._rev
        params._id = data[0].doc._id
      couch.db.save params, (err,response) ->
        if err
          console.log "error saving"
        else
          console.log "successfully saved"
      
    # console.log couch
