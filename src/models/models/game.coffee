Backbone = require "backbone"

module.exports = class Game extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "Game"
    statsKey: null
    statsLatestUpdateDate: null
    leagueId: null 
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
      final: false
    couldDraw: false 
    legit: true
    pickCount:
      home: 0
      away: 0
      draw: 0


  secondsUntilDeadline: ->
    (@get("startDate") - new Date())/1000

  deadlineHasPassed: -> 
    @secondsUntilDeadline() < 0

  postponed: ->
    status = @get "status"
    return false unless status.text
    return true if status.text.match(/postponed/) 
    return false
    
  homeWin: ->
    status = @get "status"
    return null unless status.final
    status.score.home > status.score.away

  awayWin: ->
    status = @get "status"
    return null unless status.final
    status.score.away > status.score.home

  draw: ->
    return null unless @get("couldDraw")
    status = @get "status"
    return null unless status.final
    status.score.away == status.score.home

  final: ->
    @get("status").final
