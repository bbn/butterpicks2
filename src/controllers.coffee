require "./date"
_ = require "underscore"
util = require "util"
request = require "request"

couch = require "./couch"
models = require "./models"
require "./model-server-utils"

Game = models.Game
Period = models.Period
User = models.User
UserPeriod = models.UserPeriod

journey = require "journey"
exports.router = new journey.Router
exports.router.map ->
  

  @root.bind (req,res) ->
    res.send "butterpicks2"


  @get("/facebook-object").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send err.status_code,{},err if err
      res.send 
        requestParams: params
        data: body


  @post("/user").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId
    return res.send 400,{},{error:"no email param"} unless params.email
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send 500,{},err if err
      return res.send 409,{},"user already exists" if body.rows.length > 0
      uParams = _(params).clone()
      uParams.createdDate = new Date()
      u = new User(uParams)
      u.save u.toJSON(),
        error: (model,response) -> res.send response.status_code,{},response
        success: (model,response) ->
          res.send
            requestParams: params
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
      return res.send err.status_code,{},err if err
      value = if body.rows.length then body.rows[0].value else null
      res.send 
        requestParams: params
        butters: value


  @post("/game").bind (req,res,params) ->
    Game.createOrUpdateGameFromStatsAttributes params,
      error: (_,response) -> res.send response.status_code,{},response
      success: (game,response) -> 
        res.send 
          requestParams: params
          data: game.toJSON()


  @get("/period").bind (req,res,params) ->
    for param in ["category","leagueStatsKey","date"]
      return res.send 400,{},{error:"no #{param} param"} unless params[param]
    periodId = Period.getCouchId params
    p = new Period({ id:periodId })
    p.fetch
      error: (model,response) -> res.send response.status_code,{},response
      success: (model,response) -> 
        res.send 
          requestParams: params
          data: model.toJSON()


  @get("/user-period").bind (req,res,params) ->
    return res.send 400,{},{error:"need either or both userId and periodId param"} unless params.userId or params.periodId
    if params.userId and params.periodId
      f = UserPeriod.fetchForUserAndPeriod
    else if params.periodId
      f = UserPeriod.fetchForPeriod
    else if params.userId
      f = UserPeriod.fetchForUser
    f params,
      error: (_,response) -> res.send response.status_code,{},response
      success: (data,response) -> 
        res.send 
          requestParams: params
          data: data
