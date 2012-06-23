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
    leagueId: null
    category: null
    withinDate: null

  work: (options) ->
    @fetchOrCreatePeriod
      error: options.error
      success: (period) =>
        @period = period
        @period.fetchGames
          error: options.error
          success: (games) =>
            @games = games
            process = if @games then @updatePeriod else @deletePeriod
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
    console.log "TODO: only updateUserPeriods if results of games have changed significantly"
    @updateUserPeriods
      error: options.error
      success: options.success


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
    period = new Period {id:@get("periodId")}
    period.fetch
      success: options.success
      error: (model,response) =>
        console.log "FIXME: confirm it's missing and not a real error: #{util.inspect response}"
        console.log "FIXME: generalize for non-daily periods"
        withinDate = @get "withinDate"
        leagueId = @get "leagueId"
        category = @get "category"
        return options.error(model,response) unless withinDate and leagueId and category
        startDate = withinDate.clearTime()
        endDate = (new Date(startDate)).addDays 1
        period.set
          leagueId: leagueId
          category: category
          startDate: startDate
          endDate: endDate
        period.save period.toJSON(),
          error: (model,response) =>
            options.error model,response
          success: (model,response) =>
            options.success model,response

