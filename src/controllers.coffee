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
Pick = models.Pick
ButterTransaction = models.ButterTransaction

journey = require "journey"
exports.router = new journey.Router
exports.router.map ->
  

  @root.bind (req,res) ->
    res.send "butterpicks2"


  @get("/facebook-object").bind (req,res,params) ->
    return res.send 400,{},{error:"no facebookId param"} unless params.facebookId 
    couch.db.view "facebookObjects","allByFacebookId", { key:params.facebookId }, (err,body,headers) ->
      return res.send err.status_code,{},err if err
      res.send body


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
            id: model.id
            facebookId: model.get "facebookId"
            email: model.get "email"


  @get("/metrics").bind (req,res,params) ->
    user = new User { _id: params.userId }
    user.fetch
      error: (__,err) -> res.send err.status_code,{},err
      success: (user) ->
        params.startDate = new Date(params.startDate) if params.startDate
        params.endDate = new Date(params.endDate) if params.endDate
        user.fetchMetrics
          leagueId: params.leagueId
          startDate: params.startDate
          endDate: params.endDate
          error: (__,err) -> res.send err.status_code,{},err
          success: (metrics) -> res.send metrics



  @get("/butters").bind (req,res,params) ->
    return res.send 400,{},{error:"no userId param"} unless params.userId
    u = new User {_id:params.userId}
    u.getButters
      error: (_,err) -> res.send err.status_code,{},err
      success: (value) -> res.send 200,{},value


  @post("/game").bind (req,res,params) ->
    Game.createOrUpdateGameFromStatsAttributes params,
      error: (_,response) -> res.send response.status_code,{},response
      success: (game,response) -> res.send game


  @get("/period").bind (req,res,params) ->
    for param in ["category","leagueId","date"]
      return res.send 400,{},{error:"no #{param} param"} unless params[param]
    periodId = Period.getCouchId params
    p = new Period({ _id:periodId })
    p.fetch
      error: (model,response) -> res.send response.status_code,{},response
      success: (model,response) -> res.send model


  @get("/user-period").bind (req,res,params) ->
    return res.send 400,{},{error:"invalid params"} unless (params.userId and params.leagueId) or params.periodId
    if params.userId and params.periodId
      f = UserPeriod.fetchForUserAndPeriod
    else if params.periodId
      f = UserPeriod.fetchForPeriod
    else if params.userId and params.leagueId
      f = UserPeriod.fetchForUserAndLeague
    f params,
      error: (_,response) -> res.send response.status_code,{},response
      success: (data,response) -> res.send 200,{},data


  @get("/pick").bind (req,res,params) ->
    return res.send 400,{},{error:"invalid params"} unless params.userId and params.gameId
    Pick.fetchForUserAndGame params,
      error: (_,response) -> res.send response.status_code,{},response
      success: (data,response) -> 
        res.send data

  @post("/pick").bind (req,res,params) ->
    return res.send 400,{},{error:"invalid params"} unless params.userId and params.gameId
    user = new User {_id:params.userId}
    user.getButters
      error: (_,response) -> sendError response
      success: (butters) -> 
        user.butters = butters
        testUserAndGame {user:user}
    game = new Game {_id:params.gameId}
    game.fetch
      error: (_,response) -> sendError response
      success: (game,response) -> testUserAndGame {game:game}

    errorSent = false
    sendError = (couchResponse) ->
      return if errorSent
      errorSent = true
      res.send couchResponse.status_code,{},couchResponse

    @game = null
    @user = null
    testUserAndGame = (data) =>
      @game = data.game if data.game
      @user = data.user if data.user
      return unless @game and @user
      return res.send(400,{},"deadlineHasPassed") if @game.deadlineHasPassed()
      pick = new Pick(params)
      pick.game = @game
      return res.send(400,{},"not editable") unless pick.editable()
      return res.send(400,{},"invalid") unless pick.isValid()
      return res.send(400,{},"insufficient butter") if params.butter and (@user.butters <= 0)

      Pick.create _(params).extend
        error: (_,response) -> sendError response
        success: (pick,response) => 
          return res.send(pick) unless pick.get "butter"
          tr = new ButterTransaction
            userId: @user.id
            pickId: pick.id
            amount: -1
            createdDate: pick.get "createdDate"
          tr.save tr.toJSON(),
            error: (model,response) -> sendError response
            success: (model,response) -> res.send(pick)



  @put("/pick").bind (req,res,params) ->
    return res.send 400,{},{error:"invalid params"} unless params.id
    pick = new Pick {_id:params.id}
    pick.fetch
      error: (_,response) -> res.send response.status_code,{},response
      success: (pick,response) ->
        game = new Game {_id:pick.get("gameId")}
        game.fetch
          error: (_,response) -> res.send response.status_code,{},response
          success: (game,response) ->
            return res.send(400,{},"deadlineHasPassed") if game.deadlineHasPassed()
            pick.game = game
            return res.send(400,{},"not editable") unless pick.editable()
            user = new User {_id:pick.get("userId")}
            user.getButters
              error: (_,response) -> res.send response.status_code,{},response
              success: (butters) -> 
                user.butters = butters
                newButterUsed = params.butter and (not pick.get("butter"))
                butterReclaimed = pick.get("butter") and (not params.butter)
                return res.send(400,{},"insufficient butter") if newButterUsed and (user.butters <= 0)
                return res.send(400,{},"invalid params") unless pick.set params            
                pick.set { updatedDate: new Date() }
                pick.save pick.toJSON(),
                  error: (_,response) -> res.send response.status_code,{},response
                  success: (pick,response) ->
                    return res.send(pick) unless newButterUsed or butterReclaimed
                    tr = new ButterTransaction
                      userId: user.id
                      pickId: pick.id
                      amount: (if newButterUsed then -1 else 1)
                      createdDate: pick.get "updatedDate"
                    tr.save tr.toJSON(),
                      error: (model,response) -> res.send response.status_code,{},response
                      success: (model,response) -> res.send pick
