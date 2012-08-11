###
OPTIMIZATION
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
      console.log "    all games updated since #{lastUpdatedGameDate}"
      requestParams = 
        uri: statsUrl
        json: true
      request.get requestParams, (error,response,body) ->
        return console.log("!! error get api/getgamesrecentlyupdated: #{util.inspect error}") if error
        count = body.length
        console.log "+++ #{count} games to update."
        return poll() if count==0
        for gameData in body
          gameData.statsKey = gameData.key
          Game.createOrUpdateGameFromStatsAttributes gameData,
            error: (__,response) -> 
              console.log "!!! updating error: #{response}"
              if options and options.poll then poll() unless --count
            success: (game,response) -> 
              console.log "+++ updated game #{game.id}"
              if options and options.poll then poll() unless --count


