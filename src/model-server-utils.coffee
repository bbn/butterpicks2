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
Prize = models.Prize

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



User::fetchMetrics = (options) ->
  leagueId = options.leagueId or options.league.id
  startDate = if options.startDate then options.startDate.toJSON() else '1970-01-01T00:00:00.000Z'
  endDate = if options.endDate then options.endDate.toJSON() else '2070-01-01T00:00:00.000Z'
  viewParams = 
    reduce: true
    startkey: [@id,leagueId,startDate]
    endkey: [@id,leagueId,endDate]
  couch.db.view "userPeriods","metricsByUserIdAndLeagueIdAndDate", viewParams, (err,body,headers) ->
    return options.error(null,err) if err
    return options.success({}) unless body.rows[0]
    options.success body.rows[0].value

  # idea is to retrieve all metrics before the given date.

  # exampleMetrics = 
  #   pickCount: 213
  #   correctPickCount: 168
  #   riskCount: 33
  #   successfulRiskCount: 25
  #   prizes: [
  #     { id: 'adsljhkl', count:1 }
  #     { id: '278ubkjsa', count: 3 }
  #     { id: 'sadsasad', count: 1}
  #   ]


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
  return process.nextTick(-> options.success @games) if @games
  viewParams =
    startkey: [@get("leagueId"), @get("startDate").toJSON()]
    endkey:   [@get("leagueId"), @get("endDate").toJSON()]
    include_docs: true
  couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) =>
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows
    @games = ((new Game(row.doc)) for row in body.rows)
    options.success @games


Period::fetchUserPeriods = (options) ->
  UserPeriod.fetchForPeriod {periodId:@id,descending:true}, options


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
        metrics:
          points: 0
      userPeriod.save userPeriod.toJSON(), options

UserPeriod.fetchForPeriod = (params,options) ->
  high = [params.periodId, "points", 999999999999]
  low = [params.periodId, "points", -999999999999]
  viewParams =
    descending: (if params.descending then true else false)
    startkey: (if params.descending then high else low)
    endkey:   (if params.descending then low else high)
    include_docs: true
  couch.db.view "userPeriods","byPeriodIdAndMetric", viewParams, (err,body,headers) ->
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

UserPeriod::fetchPeriod = (options) ->
  return process.nextTick(-> options.success @period) if @period
  period = new Period {id:@get("periodId")}
  period.fetch
    error: options.error
    success: (period) =>
      @period = period
      options.success @period

UserPeriod::fetchGames = (options) ->
  return process.nextTick(-> options.success @games) if @games
  @fetchPeriod
    error: options.error
    success: (period) =>
      @period.fetchGames
        error: options.error
        success: (games) =>
          @games = games
          options.success @games

UserPeriod::fetchPicks = (options) ->
  @fetchGames
    error: options.error
    success: (games) =>
      @games = games
      return options.success([]) unless @games.length
      picks = []
      errorReturned = false
      # TODO the below is bad - so many DB accesses. collect into a single view!
      for game in @games
        do (game) =>
          Pick.fetchForUserAndGame {userId:@get("userId"),gameId:game.id},
            error: (__,response) =>
              options.error(response) unless errorReturned
              errorReturned = true
            success: (pick) =>
              return if errorReturned
              pick.game = game
              pick.user = @user if @user
              picks.push(pick)
              if picks.length == @games.length
                @picks = picks
                options.success @picks


UserPeriod::fetchMetrics = (options) ->
  @fetchPicks
    error: options.error
    success: (picks) =>
      metrics =
        # games: @games.length
        # allGamesFinal: _(@games).filter((game)-> game.final()).size() == @games.length
        picks: _(picks).size()
        unfinalizedPicks: _(picks).filter((pick)-> not pick.final()).size()
        homePicks: _(picks).filter((pick)-> pick.get("home")).size()
        awayPicks: _(picks).filter((pick)-> pick.get("away")).size()
        drawPicks: _(picks).filter((pick)-> pick.get("draw")).size()
        uselessPicks: _(picks).filter((pick)-> pick.useless()).size() + @games.length - _(picks).size()
        predictions: _(picks).filter((pick)-> pick.prediction()).size()
        correctPredictions: _(picks).filter((pick)-> pick.correctPrediction()).size()
        incorrectPredictions: _(picks).filter((pick)-> pick.incorrectPrediction()).size()
        risks: _(picks).filter((pick)-> pick.risk()).size()
        correctRisks: _(picks).filter((pick)-> pick.correctRisk()).size()
        incorrectRisks: _(picks).filter((pick)-> pick.incorrectRisk()).size()
        safeties: _(picks).filter((pick)-> pick.safety()).size()
        butters: _(picks).filter((pick)-> pick.get("butter")).size()
        points: _(picks).reduce (memo,pick) -> memo + pick.points()





UserPeriod::determinePrizes = (options) ->
  return options.error("no user loaded") unless @user
  return options.error("no period loaded") unless @period
  return options.error("no period.games loaded") unless options.games or (@period and @period.games)
  return options.error("no picks loaded") unless @picks
  Prize.fetchAllForLeague {id:@leagueId},
    error: options.error
    success: (prizes) =>
      @metrics = {}
      @user.fetchMetrics 
        endDate: @periodstartDate
        leagueId: @leagueId
        error: options.error
        success: (userMetrics) =>
          _(@metrics).extend userMetrics
          @period.fetchMetrics
            error: options.error
            success: (periodMetrics) =>
              _(@metrics).extend periodMetrics
              @fetchMetrics
                error: options.error
                success: (userPeriodMetrics) =>
                  _(@metrics).extend userPeriodMetrics
                  for prize in prizes
                    prize.currentStatus = 
                      eligible: prize.eligible @metrics
                      possible: prize.possible @metrics
                      success:  prize.success  @metrics
                  options.success prizes



Prize.fetchAllForLeague = (league,options) ->
  couch.db.view "prizes","byLeagueId",{key:league.id,include_docs:true},(err,body,headers) ->
    return options.error(null,err) if err
    return options.success([],headers) unless body.rows.length
    prizes = ((new Prize(row.doc)) for row in body.rows)
    options.success prizes