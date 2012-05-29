Backbone = require "backbone"

module.exports = class Game extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "Game"
    statsKey: null
    statsLatestUpdateDate: null
    league: 
      statsKey: null
      abbreviation: null
    awayTeam:
      statsKey: null
      name: null
    homeTeam:
      statsKey: null
      name: null
    startDate: null
    status:
      score:
        away: null
        home: null
      text: null #eg, "3rd period"
      final: null
      legit: null
      postponed: null
    pickCount:
      home: null
      away: null
      draw: null
    basePeriodKey: null


  secondsUntilDeadline: ->
    start = @get "startDate"
    now = new Date()
    return start - now

      
