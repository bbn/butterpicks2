util = require "util"

couch = require "./couch"
models = require "./models"

journey = require "journey"
exports.router = new journey.Router
exports.router.map ->
  
  @root.bind (req,res) ->
    res.send "butterpicks2"


  @get("/facebook-object").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body


  @post("/user/create").bind (req,res,params) ->
    return res.send 403,{},{error:"no facebookId param"} unless params.facebookId
    return res.send 403,{},{error:"no email param"} unless params.email
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      return res.send 500,{},"user already exists" if body.rows.length > 0
      params.createdDate = new Date()
      u = new models.User(params)
      u.save u.toJSON(),
        error: (model,response) -> res.send 500,{},response
        success: (model,response) ->
          res.send 200,{},
            id: model.id
            facebookId: model.get "facebookId"
            email: model.get "email"




