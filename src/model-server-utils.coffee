util = require "util"

models = require "./models"
Game = models.Game
Period = models.Period

workers = require "./workers"
PeriodUpdateJob = workers.PeriodUpdateJob


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
    success: (p,response) -> options.success p,response #TODO can I just say options.success?
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


Period::fetchGames = ->
  console.log "TODO use couchdb view"  