Job = require "./job"
_ = require "underscore"
util = require "util"
require "../../date"
Backbone = require "backbone"
couch = require "../../couch"
models = require "../../models"
Period = models.Period
Game = models.Game
UserPeriodUpdateJob = require "./user-period-update-job"


module.exports = class PeriodUpdateJob extends Job

  idAttribute: "_id"

  defaults:
    job: true
    doctype: "PeriodUpdateJob"
    createdDate: new Date()
    periodId: null
    gameId: null

    # leagueId: null
    # category: null
    # withinDate: null

  work: (options) ->
    @fetchOrCreatePeriod
      error: options.error
      success: (period) =>
        @period = period
        @period.fetchGames
          error: options.error
          success: (games) =>
            process = if games.length then @updatePeriod else @deletePeriod
            process.call @,
              error: options.error
              success: => options.success @


  deletePeriod: (options) ->
    @period.destroy
      error: options.error
      success: =>
        @updateUserPeriods
          error: options.error
          success: options.success


  updatePeriod: (options) ->
    @updateFinalStatus
      error: options.error
      success: =>
        console.log "OPTIMIZATION: only updateUserPeriods if results of games have changed significantly"
        @updateUserPeriods
          error: options.error
          success: options.success


  updateFinalStatus: (options) ->
    final = true
    for game in @period.games
      final = false unless game.get("status").final
    return options.success() unless final
    @period.save {final:true}, options


  updateUserPeriods: (options) ->
    @period.fetchUserPeriods
      error: options.error
      success: (userPeriods) ->
        count = userPeriods.length
        options.success() unless count
        errorCalled = false
        for userPeriod in userPeriods
          do (userPeriod) ->
            job = new UserPeriodUpdateJob {userPeriodId: userPeriod.id}
            job.save job.toJSON(),
              success: -> options.success() unless --count
              error: (model,response) ->
                unless errorCalled
                  errorCalled = true
                  options.error model,response


  fetchOrCreatePeriod: (options) ->
    return @fetchPeriod(options) if @get("periodId")
    game = new Game { _id: @get("gameId") }
    game.fetch
      error: options.error
      success: (game) =>
        Period.getOrCreateBasePeriodForGame game, options


  fetchPeriod: (options) ->
    period = new Period {_id:@get("periodId")}
    period.fetch options
