util = require "util"

couch = require "./couch"
models = require "./models"

journey = require "journey"
exports.router = new journey.Router
exports.router.map ->
  
  @root.bind (req,res) ->
    res.send "butterpicks2"


  @get("/facebook-object").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      res.send body


  @post("/user/create").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId
    return res.send 400,{},{error:"no email param"} unless params.email
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      return res.send 409,{},"user already exists" if body.rows.length > 0
      params.createdDate = new Date()
      u = new models.User(params)
      u.save u.toJSON(),
        error: (model,response) -> res.send 500,{},response
        success: (model,response) ->
          res.send 200,{},
            id: model.id
            facebookId: model.get "facebookId"
            email: model.get "email"


  @get("/butters").bind (req,res,params) ->
    return res.send 400,{},{error:"no userId param"} unless params.userId
    viewParams =
      group_level: 1
      startkey: [params.userId,'"1970-01-01T00:00:00.000Z"']
      endkey: [params.userId,'"2070-01-01T00:00:00.000Z"']
    couch.db.view "butters","byUserId", viewParams, (err,body,headers) ->
      return res.send 500,{},err if err
      value = if body.rows.length then body.rows[0].value else null
      res.send 
        userId: params.userId
        butters: value

