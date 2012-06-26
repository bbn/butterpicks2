util = require "util"

couch = require "./couch"
models = require "./models"
User = models.User
Game = models.Game
League = models.League
Period = models.Period
UserPeriod = models.UserPeriod
Pick = models.Pick
ButterTransaction = models.ButterTransaction

workers = require "./workers"
PeriodUpdateJob = workers.PeriodUpdateJob


League.fetchForStatsKey = (statsKey,options) ->
  couch.db.view "leagues","byStatsKey",{key:statsKey,include_docs:true},(err,body,headers) ->
    return options.error(null,err) if err
    return options.success(null,headers) unless body.rows.length
    league = new League(body.rows[0].doc)
    options.success league


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
  League.fetchForStatsKey params.leagueStatsKey,
    error: options.error
    success: (league,response) =>
      return options.error(null,"no league for statsKey #{params.leagueStatsKey}") unless league
      @set {leagueId:league.id,startDate:new Date(params.starts_at*1000)}
      @fetchBasePeriodId
        error: options.error
        success: (basePeriodId) =>
          oldBasePeriodId = basePeriodId
          attributes = Game.attrFromStatServerParams params
          attributes.leagueId = league.id
          @save attributes, 
            error: options.error
            success: (game,gameCouchResponse) =>
              game.fetchBasePeriodId
                error: options.error
                success: (newBasePeriodId) =>
                  periodUpdateJobParams =
                    periodId: newBasePeriodId
                    leagueId: league.id
                    category: league.basePeriodCategory
                    withinDate: game.get "startDate"
                  PeriodUpdateJob.create periodUpdateJobParams,
                    error: options.error
                    success: =>
                      unless oldBasePeriodId and oldBasePeriodId != newBasePeriodId
                        return options.success game,gameCouchResponse
                      PeriodUpdateJob.create {periodId: oldBasePeriodId},
                        error: options.error
                        success: -> options.success game,gameCouchResponse 


Game.attrFromStatServerParams = (params) ->
  attributes =
    statsKey: params.statsKey
    statsLatestUpdateDate: new Date(params.updated_at*1000)
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


Game::fetchBasePeriodId = (options) ->
  return options.error(null,"param error") unless @get("leagueId") and @get("startDate")
  league = new League {id:@get("leagueId")}
  league.fetch
    error: options.error
    success: (league,response) =>
      id = Period.getCouchId
        leagueId: league.id
        category: league.get "basePeriodCategory"
        date: @get "startDate"
      options.success id


Period.getCouchId = (params) ->
  switch params.category
    when "daily"
      d = new Date(params.date)
      dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
      periodId = "#{params.leagueId}_#{params.category}_#{dateString}"
    when "lifetime"
      periodId = "#{params.leagueId}_#{params.category}"
  periodId


Period.getOrCreateBasePeriodForGame = (game,options) ->
  game.fetchBasePeriodId
    error: options.error
    success: (basePeriodId) ->
      p = new Period({ id:basePeriodId })
      p.fetch
        success: options.success
        error: (p,response) -> 
          console.log "FIXME confirm that error comes from absent model: #{util.inspect response}"
          league = new League {id:game.get("leagueId")}
          league.fetch
            error: options.error
            success: (league,response) ->
              gameDate = game.get "startDate"
              switch league.get("basePeriodCategory") 
                when "daily"
                  startDate = new Date(gameDate.getFullYear(), gameDate.getMonth(), gameDate.getDate())
                  endDate = (new Date(startDate)).add {days:1} 
                when "weekly"
                  console.log "FIXME no code in place for weekly categories"
                  console.log "FIXME adjust endDate depending on category of period"
              data =
                leagueId: game.get("leagueId")
                category: league.get("basePeriodCategory") 
                startDate: startDate
                endDate: endDate
              p.save data,options


Period::fetchGames = (options) ->
  viewParams =
    startkey: [@get("leagueId"), @get("startDate").toJSON()]
    endkey:   [@get("leagueId"), @get("endDate").toJSON()]
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
        leagueId: p.get("leagueId")
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
    startkey: [params.userId, params.leagueId, (new Date(1970,1,1)).toJSON()]
    endkey:   [params.userId, params.leagueId, (new Date(2070,1,1)).toJSON()]
    include_docs: true
  couch.db.view "userPeriods","byUserIdAndLeagueAndDate", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    userPeriods = ((new UserPeriod(row.doc)) for row in body.rows)
    options.success userPeriods


UserPeriod::fetchPicks = (options) ->
  return options.error("games not loaded") unless @games
  return options.success([]) unless @games.length
  picks = []
  errorReturned = false
  for game in @games
    do (game) =>
      Pick.fetchForUserAndGame {userId:@get("userId"),gameId:game.id},
        error: (_,response) =>
          options.error(response) unless errorReturned
          errorReturned = true
        success: (pick) =>
          return if errorReturned
          pick.game = game
          pick.user = @user if @user
          picks.push(pick)
          options.success(picks) if picks.length == @games.length



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
