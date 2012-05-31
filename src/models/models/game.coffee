Backbone = require "backbone"

module.exports = class Game extends Backbone.Model

  defaults:
    doctype: "Game"
    statsKey: null
    statsLatestUpdateDate: null
    league: 
      statsKey: null
      abbreviation: null
    awayTeam:
      statsKey: null
      location: null
      name: null
    homeTeam:
      statsKey: null
      location: null
      name: null
    startDate: null
    status:
      score:
        away: null
        home: null
      text: null #eg, "3rd period"
      final: null
      legit: null
    pickCount:
      home: null
      away: null
      draw: null
    basePeriodKey: null


  postponed: ->
    status = @get "status"
    return false unless status.text
    return true if status.text.match /postponed/
    return false
    

  secondsUntilDeadline: ->
    start = @get "startDate"
    now = new Date()
    return start - now

      
