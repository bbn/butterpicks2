_ = require "underscore"
util = require "util"
require "../../date"
Backbone = require "backbone"
couch = require "../../couch"
models = require "../../models"
Period = models.Period
Game = models.Game


module.exports = class PeriodUpdateJob extends Backbone.Model

  @doctype: "PeriodUpdateJob"

  idAttribute: "_id"

  defaults:
    job: true
    doctype: "PeriodUpdateJob" #FIXME how to refer to the class variable?
    createdDate: new Date()
    periodId: null
    league:
      statsKey: null
      abbreviation: null
    category: null
    withinDate: null

  work: (options) ->
    @fetchOrCreatePeriod
      error: options.error
      success: (period) =>
        
        # load all games associated with period
        #   are there no games?
        #     delete the period
        #     fetch associated user periods
        #       delete user periods
        #   have the results of the games changed since last update? compare with some kind of cached profile
        #     should we recalculate all user periods?
        #       fetch all user periods
        #         recalc each user period (another worker)
        options.success @


  fetchOrCreatePeriod: (options) ->
    period = new Period({ id: @get "periodId" })
    period.fetch
      success: options.success
      error: (model,response) =>
        console.log "FIXME: confirm it's missing and not a real error: #{util.inspect response}"
        console.log "FIXME: generalize for non-daily periods"
        withinDate = @get "withinDate"
        league = @get "league"
        category = @get "category"
        return options.error(model,response) unless withinDate and league and category
        startDate = withinDate.clearTime()
        endDate = (new Date(startDate)).addDays 1
        period.set
          league: league
          category: category
          startDate: startDate
          endDate: endDate
        period.save period.toJSON(),
          error: (model,response) =>
            options.error model,response
          success: (model,response) =>
            options.success model,response



  @create: (params,options) ->
    j = new @
    j.save params,
      error: options.error
      success: (job,response) =>
        options.success job,response
        @startWorking() unless @workSuspended

  
  @workSuspended: false

  @workInProgress: false

  @startWorking: ->
    console.log "@startWorking"
    @doWork() unless @workInProgress
    
  @doWork: ->
    console.log "@doWork"
    @workInProgress = true
    @getNext
      error: (model,response) => 
        console.log "!!! fetching next job error: #{util.inspect response}"
        @doWork()
      success: (model,response) =>
        return @stopWorking() unless model
        model.work
          error: (_,response) => 
            console.log "!!! work error: #{util.inspect response}"
            @doWork()
          success: (model) =>
            model.destroy
              error: => 
                console.log "!!! deleting job error: #{util.inspect response}"
                @doWork()
              success: => @doWork()

  @stopWorking: ->
    console.log "@stopWorking"
    @workInProgress = false

  @getNext: (options) ->
    viewParams =
      startkey: [@doctype,'1970-01-01T00:00:00.000Z']
      endKey: [@doctype,'2070-01-01T00:00:00.000Z']
      include_docs: true
      limit: options.limit or 1
    couch.db.view "jobs","byType", viewParams, (err,body,headers) =>
      return options.error(null,err) if err
      jobs = (new @(row.doc) for row in body.rows)
      jobs = jobs[0] if viewParams.limit == 1
      options.success jobs, headers
