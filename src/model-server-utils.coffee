models = require "./models"


models.Game::updateAttributesFromStatServerParams = (params, options) ->
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
  @save attributes, options


models.Game::getBasePeriodId = ->
  return null unless @get("leagueStatsKey") and @get(startDate)
  models.Period.getCouchId
    leagueStatsKey: @get "leagueStatsKey"
    category: "daily" #FIXME
    date: @get "startDate"



models.Period.getCouchId = (params) ->
  switch params.category
    when "daily"
      d = new Date(params.date)
      dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
      periodId = "#{params.leagueStatsKey}_#{params.category}_#{dateString}"
    when "lifetime"
      periodId = "#{params.leagueStatsKey}_#{params.category}"
  periodId


models.Period.getOrCreateBasePeriodForGame = (game,options) ->
  basePeriodId = game.getBasePeriodId()
  basePeriod = new models.Period({ id:periodId })
  p.fetch
    success: (p,response) -> options.success p,response #TODO can I just say options.success?
    error: (p,response) -> 
      #FIXME confirm that error comes from absent model
      console.log "+++ creating #{p.id}"
      gameDate = game.get "startDate"
      startDate = new Date(gameDate.getFullYear(), gameDate.getMonth(), gameDate.getDate())
      endDate = (new Date(startDate)).add {days:1} #FIXME
      data =
        league:
          abbreviation: game.get("league").abbreviation
          statsKey: game.get("league").statsKey
        category: "daily" #FIXME
        startDate: startDate
        endDate: endDate
      p.save data,options
