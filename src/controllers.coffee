util = require "util"
couch = require "./couch"

journey = require "journey"

controllers = exports
controllers.router = new journey.Router
controllers.router.map ->
  
  @root.bind (req,res) ->
    res.send "butterpicks2"

  @get("/user").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookDocs","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body

  @post("/user").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId
    couch.db.insert params, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body

