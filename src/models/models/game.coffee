League = require "./league"
Period = require "./period"

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

  league: null

  validate: (attr) ->
    return "bad doctype" unless attr.doctype=="Game"
    return "no statsKey" unless attr.statsKey
    return "no leagueId" unless attr.leagueId
    return "no startDate" unless attr.startDate

  initialize: (attr) ->
    @set({_id:@getCouchId()}) unless @get("_id")

  @couchIdForStatsKey: (statsKey) ->
    "game_#{statsKey}"

  getCouchId: ->
    @constructor.couchIdForStatsKey @get("statsKey")


  fetchLeague: (options) ->
    return options.success(@league) if @league
    League.fetchById
      id: @get "leagueId"
      error: options.error
      success: (league) =>
        @league = league
        options.success @league

  fetchBasePeriodId: (options) ->
    return options.error(null,"no leagueId") unless @get("leagueId")
    return options.error(null,"no startDate") unless @get("startDate")
    @fetchLeague
      error: options.error
      success: (league) =>
        id = Period.getCouchId
          leagueId: league.id
          category: league.get "basePeriodCategory"
          date: @get "startDate"
        options.success id



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
