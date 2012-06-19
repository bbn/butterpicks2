util = require "util"

couch = require "./couch"
models = require "./models"
User = models.User
Game = models.Game
Period = models.Period
UserPeriod = models.UserPeriod
Pick = models.Pick
ButterTransaction = models.ButterTransaction

workers = require "./workers"
PeriodUpdateJob = workers.PeriodUpdateJob



User::getButters = (options) ->
  viewParams =
    group_level: 1
    startkey: [@.id,'1970-01-01T00:00:00.000Z']
    endkey: [@.id,'2070-01-01T00:00:00.000Z']
  couch.db.view "butters","byUserId", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    value = if body.rows.length then body.rows[0].value else null
    options.success value


User::fetchButterTransactions = (options) ->
  viewParams =
    reduce: false
    startkey: [@.id,'1970-01-01T00:00:00.000Z']
    endkey: [@.id,'2070-01-01T00:00:00.000Z']
    include_docs: true
  couch.db.view "butters","byUserId", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    trannies = ((new ButterTransaction(row.doc)) for row in body.rows)
    options.success trannies


Game::getCouchId = ->
  "game_#{@get 'statsKey'}"


Game::initialize = ->
  if @get("statsKey") then @set({id:@getCouchId()}) unless @get("id")


Game.createOrUpdateGameFromStatsAttributes = (params,options) ->
  g = new Game { statsKey: params.statsKey }
  g.fetch
    error: (game,response) ->
      return options.error(game,response) unless response.status_code == 404
      game.updateFromStatsAttributes params,options
    success: (game,response) ->
      game.updateFromStatsAttributes params,options


Game::updateFromStatsAttributes = (params,options) ->
  oldBasePeriodId = @basePeriodId()
  attributes = Game.attrFromStatServerParams params
  @save attributes, 
    error: options.error
    success: (game,gameCouchResponse) =>
      console.log "FIXME assumption of daily category in PeriodUpdateJob creation"
      periodUpdateJobParams =
        periodId: game.basePeriodId()
        league: game.get "league"
        category: "daily"
        withinDate: game.get "startDate"
      PeriodUpdateJob.create periodUpdateJobParams,
        error: options.error
        success: =>
          unless oldBasePeriodId and oldBasePeriodId != game.basePeriodId()
            return options.success game,gameCouchResponse
          PeriodUpdateJob.create {periodId: oldBasePeriodId},
            error: options.error
            success: -> options.success game,gameCouchResponse 


Game.attrFromStatServerParams = (params) ->
  attributes =
    statsKey: params.statsKey
    statsLatestUpdateDate: new Date(params.updated_at*1000)
    league:
      abbreviation: params.league
      statsKey: params.leagueStatsKey
    awayTeam:
      statsKey: params.away_team.key
      location: params.away_team.location
      name: params.away_team.name
    homeTeam:
      statsKey: params.home_team.key
      location: params.home_team.location
      name: params.home_team.name
    startDate: new Date(params.starts_at*1000)
    status:
      score:
        away: params.away_score
        home: params.home_score
      text: params.status
      final: params.final
    legit: params.legit


Game::basePeriodId = ->
  return null unless @get("leagueStatsKey") and @get(startDate)
  console.log "FIXME assumption of daily category for basePeriodId"
  Period.getCouchId
    leagueStatsKey: @get "leagueStatsKey"
    category: "daily"
    date: @get "startDate"


Period.getCouchId = (params) ->
  switch params.category
    when "daily"
      d = new Date(params.date)
      dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
      periodId = "#{params.leagueStatsKey}_#{params.category}_#{dateString}"
    when "lifetime"
      periodId = "#{params.leagueStatsKey}_#{params.category}"
  periodId


Period.getOrCreateBasePeriodForGame = (game,options) ->
  basePeriodId = game.basePeriodId()
  basePeriod = new Period({ id:periodId })
  p.fetch
    success: options.success
    error: (p,response) -> 
      console.log "FIXME confirm that error comes from absent model: #{util.inspect response}"
      console.log "+++ creating #{p.id}"
      gameDate = game.get "startDate"
      startDate = new Date(gameDate.getFullYear(), gameDate.getMonth(), gameDate.getDate())
      endDate = (new Date(startDate)).add {days:1} 
      console.log "FIXME assumption of daily period"
      console.log "FIXME adjust endDate depending on category of period"
      data =
        league:
          abbreviation: game.get("league").abbreviation
          statsKey: game.get("league").statsKey
        category: "daily" 
        startDate: startDate
        endDate: endDate
      p.save data,options


Period::fetchGames = (options) ->
  viewParams =
    startkey: [@get("league").statsKey, @get("startDate").toJSON()]
    endkey:   [@get("league").statsKey, @get("endDate").toJSON()]
    include_docs: true
  couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    games = ((new Game(row.doc)) for row in body.rows)
    options.success games


Period::fetchUserPeriods = (options) ->
  viewParams =
    descending: true
    startkey: [@.id, 99999999999]
    endkey:   [@.id, -99999999999]
    include_docs: true
  couch.db.view "userPeriods","byPeriodIdAndPoints", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    userPeriods = ((new UserPeriod(row.doc)) for row in body.rows)
    options.success userPeriods


UserPeriod.getCouchId = (params) ->
  "#{params.userId}_#{params.periodId}"

UserPeriod.fetchForUserAndPeriod = (params,options) ->
  userPeriodId = UserPeriod.getCouchId params
  userPeriod = new UserPeriod { id: userPeriodId }
  userPeriod.fetch options

UserPeriod.createForUserAndPeriod = (params,options) ->
  userPeriodId = UserPeriod.getCouchId params
  p = new Period { id: params.periodId }
  p.fetch
    error: options.error
    success: (p,response) ->      
      userPeriod = new UserPeriod
        id: userPeriodId
        periodId: p.id
        leagueStatsKey: p.get("league").statsKey
        periodStartDate: p.get("startDate")
        periodCategory: p.get("category")
        userId: params.userId
      userPeriod.save userPeriod.toJSON(), options

UserPeriod.fetchForPeriod = (params,options) ->
  high = [params.periodId, 999999999999]
  low = [params.periodId, -999999999999]
  viewParams =
    descending: (if params.descending then true else false)
    startkey: (if params.descending then high else low)
    endkey:   (if params.descending then low else high)
    include_docs: true
  couch.db.view "userPeriods","byPeriodIdAndPoints", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    userPeriods = ((new UserPeriod(row.doc)) for row in body.rows)
    options.success userPeriods

UserPeriod.fetchForUserAndLeague = (params,options) ->
  viewParams =
    startkey: [params.userId, params.leagueStatsKey, (new Date(1970,1,1)).toJSON()]
    endkey:   [params.userId, params.leagueStatsKey, (new Date(2070,1,1)).toJSON()]
    include_docs: true
  couch.db.view "userPeriods","byUserIdAndLeagueAndDate", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    userPeriods = ((new UserPeriod(row.doc)) for row in body.rows)
    options.success userPeriods


Pick.getCouchId = (params) ->
  return null unless params.userId and params.gameId
  "#{params.userId}_#{params.gameId}"


Pick.create = (params,options) ->
  return options.error("userId, gameId params plz") unless params.gameId and params.userId
  pick = new Pick(params)
  d = new Date()
  pick.set 
    id:Pick.getCouchId params
    createdDate: d
    updatedDate: d
  pick.save pick.toJSON(),options


Pick.fetchForUserAndGame = (params,options) ->
  pickId = Pick.getCouchId params
  pick = new Pick { id: pickId }
  pick.fetch options
