util = require "util"
couch = require "./couch"

journey = require "journey"

controllers = exports
controllers.router = new journey.Router
controllers.router.map ->
  
  @root.bind (req,res) ->
    res.send "butterpicks2"

  @get("/facebook-object").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body

  @post("/facebook-object").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId
    return res.send 403,{},{error:"no email param"} unless params.email
    couch.db.insert params, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body

