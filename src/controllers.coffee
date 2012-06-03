require "./date"
util = require "util"
request = require "request"

couch = require "./couch"
models = require "./models"
require "./model-server-utils"
Game = models.Game
Period = models.Period
User = models.User

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


  @post("/user").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId
    return res.send 400,{},{error:"no email param"} unless params.email
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      return res.send 409,{},"user already exists" if body.rows.length > 0
      params.createdDate = new Date()
      u = new User(params)
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
      startkey: [params.userId,'1970-01-01T00:00:00.000Z']
      endkey: [params.userId,'2070-01-01T00:00:00.000Z']
    couch.db.view "butters","byUserId", viewParams, (err,body,headers) ->
      return res.send 500,{},err if err
      value = if body.rows.length then body.rows[0].value else null
      res.send 
        userId: params.userId
        butters: value


  @get("/period").bind (req,res,params) ->
    return res.send 400,{},{error:"no category param"} unless params.category
    return res.send 400,{},{error:"no leagueStatsKey param"} unless params.leagueStatsKey
    return res.send 400,{},{error:"no date param"} unless params.date
    periodId = Period.getCouchId params
    p = new Period({ id:periodId })
    p.fetch
      error: (model,response) -> res.send response
      success: (model,response) -> res.send model.toJSON()


  @post("/game").bind (req,res,params) ->
    Game.createOrUpdateGameFromStatsAttributes params,
      error: (_,response) -> res.send 500,{},response
      success: (game,response) -> res.send game.toJSON()




