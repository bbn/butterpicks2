require "./date"
util = require "util"
request = require "request"

couch = require "./couch"
models = require "./models"
require "./model-server-utils"

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
    periodId = models.Period.getCouchId params
    p = new models.Period({ id:periodId })
    p.fetch
      error: (model,response) -> res.send response
      success: (model,response) -> res.send model.toJSON()


  @post("/game").bind (req,res,params) ->
    g = new models.Game({ statsKey: params.statsKey, id: "game_#{params.statsKey}" })
    console.log "+++ received new Game data for #{g.id}"    
    g.fetch
      error: (model,response) -> createGame model
      success: (model,response) -> updateGame model
    createGame = (game) ->
      console.log "+++ creating #{game.id}"
      updateGame game
    updateGame = (game) =>
      oldAttributes = game.toJSON()
      oldBasePeriodId = game.getBasePeriodId()
      game.updateAttributesFromStatServerParams params,
        error: (game,response) ->
          console.log "!!! error saving game: #{util.inspect response}"
          res.send 500,{},response
        success: (game,response) -> 
          models.Period.getOrCreateBasePeriodForGame game,
            error: (p,response) ->
              console.log "error creating period #{p.id}: #{util.inspect response}"
              return updatePeriods game,oldAttributes # TODO recurse a bad idea?
            success: (p,response) ->
              if p.get "final"
                # TODO if the result has materially changed, 
                # recalculate everybody's totals for one or both periods
              if oldBasePeriodId != p.id
                # TODO delete the old base period if there are no games and all associated participant periods

              res.send model.toJSON()

