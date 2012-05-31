###
TODO
stats server should ping this app directly when a change is made.
refactor this code so that it accepts updated game data in a request.
###


util = require "util"
request = require "request"
couch = require "./couch"
models = require "./models"
Game = models.Game


exports.getMostRecentlyUpdatedGameDate = getMostRecentlyUpdatedGameDate = (options) ->
  viewParams =
    descending: true
    limit: 1
  couch.db.view "games","mostRecentlyUpdated", viewParams, (err,body,headers) ->
    return options.error null,err if err
    date = if body.rows.length then new Date(body.rows[0].key) else null
    options.success date, body


pollInterval = null
exports.poll = poll = (interval) ->
  pollInterval = interval if interval
  setTimeout( (-> updateGames({poll:true})), pollInterval) if pollInterval


updateGames = (options) ->
  getMostRecentlyUpdatedGameDate
    error: (_,error) ->
      console.log "!! error in getMostRecentlyUpdatedGameDate: #{util.inspect error}"
    success: (lastUpdatedGameDate,response) ->
      integerDate = if lastUpdatedGameDate then parseInt(lastUpdatedGameDate.valueOf()/1000) else 0
      statsUrl = "http://butterstats.appspot.com/api/getgamesrecentlyupdated?since=#{integerDate}"
      console.log "+++ fetching #{statsUrl}"
      requestParams = 
        uri: statsUrl
        json: true
      request.get requestParams, (error,response,body) ->
        return console.log("!! error get api/getgamesrecentlyupdated: #{util.inspect error}") if error
        count = body.length
        console.log "+++ #{count} games to update."
        periodsToUpdate = []
        for gameData in body
          do (gameData) ->
            g = new Game({ statsKey: gameData.key, id: "game_#{gameData.key}" })
            g.fetch
              error: (model,response) ->
                console.log "+++ creating #{model.id}"
                updateGame model
              success: (model,response) ->
                console.log "+++ updating #{model.id}"
                # TODO add current base period to periodsToUpdate
                updateGame model
            updateGame = (model) ->
              newAttributes =
                statsKey: gameData.key
                statsLatestUpdateDate: new Date(gameData.updated_at*1000)
                league:
                  abbreviation: gameData.league
                  statsKey: gameData.leagueStatsKey
                awayTeam:
                  statsKey: gameData.away_team.key
                  location: gameData.away_team.location
                  name: gameData.away_team.name
                homeTeam:
                  statsKey: gameData.home_team.key
                  location: gameData.home_team.location
                  name: gameData.home_team.name
                startDate: new Date(gameData.starts_at*1000)
                status:
                  score:
                    away: gameData.away_score
                    home: gameData.home_score
                  text: gameData.status
                  final: gameData.final
                  legit: gameData.legit
              # TODO add new base period to periodsToUpdate
              # basePeriod =
              # newAttributes.basePeriod =
              g.save newAttributes,
                error: (model,response) ->
                  console.log "!!! error saving game: #{util.inspect response}"

                success: (model,response) ->
                  count--
                  if count == 0
                    # TODO update all assembled periods
                    poll() if options and options.poll


