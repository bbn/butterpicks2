util = require "util"

couch = require "../lib/couch"
Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"
Period = models.Period
Game = models.Game

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createPeriodUpdateJob = 

  testCreatePeriodUpdateJob: (test) ->
    PeriodUpdateJob.workSuspended = true
    @periodId = "nlxuiqnonorq2rq2"
    PeriodUpdateJob.create {periodId:@periodId},
      error: logErrorResponse ""
      success: (model,response) =>
        test.ok model
        test.equal model.get("doctype"), "PeriodUpdateJob"
        test.ok model.id
        @modelId = model.id
        test.equal model.get("periodId"), @periodId
        test.ok model.get("job")
        test.done()

  tearDown: (callback) ->
    j = new PeriodUpdateJob {id:@modelId}
    j.fetch
      error: logErrorResponse ""
      success: ->
        j.destroy 
          error: logErrorResponse ""
          success: -> callback()


exports.periodUpdateJobQueries = 

  setUp: (callback) ->
    PeriodUpdateJob.workSuspended = true
    @periodId = "78x2oruqnlufhfklahs"
    PeriodUpdateJob.create {periodId:@periodId},
      error: logErrorResponse "setUp"
      success: (model,_) => 
        @modelId = model.id
        callback()

  tearDown: (callback) ->
    j = new PeriodUpdateJob {id:@modelId}
    j.fetch
      error: logErrorResponse "tearDown fetch"
      success: ->
        j.destroy 
          error: logErrorResponse "tearDown destroy"
          success: -> callback()

  testPeriodUpdateJobCreatedDateView: (test) ->
    viewParams =
      startkey: ["PeriodUpdateJob",'1970-01-01T00:00:00.000Z']
      endKey: ["PeriodUpdateJob",'2070-01-01T00:00:00.000Z']
      include_docs: true
      limit: 1
    couch.db.view "jobs","byType", viewParams, (err,body,headers) =>
      test.expect 7
      test.ok (not err), "err. design docs not configured?"
      test.ok body, "body"
      if body
        test.ok body.rows
        test.equal body.rows.length,1
        job = body.rows[0]
        test.equal job.id, @modelId
        test.ok job.doc
        test.equal job.doc.periodId, @periodId, "no period id"
      test.done()

  testPeriodUpdateJobGetNext: (test) ->
    PeriodUpdateJob.getNext
      error: logErrorResponse ""
      success: (job,response) =>
        test.ok job
        test.equal job.id, @modelId
        test.equal job.get("periodId"), @periodId
        test.done()


exports.periodUpdateJobWork = 

  setUp: (callback) ->
    @periodData = 
      league:
        statsKey: "xe2noiuhw9x23i"
      category: "daily"
      startDate: new Date("Jan 1, 2011")
      endDate: new Date("Jan 2, 2011")
    @periodData.id = Period.getCouchId
      leagueStatsKey: @periodData.league.statsKey
      category: @periodData.category
      withinDate: @periodData.startDate
    p = new Period(@periodData)
    p.save p.toJSON(),
      error: -> logErrorResponse ""
      success: (model,response) =>
        @period = model

        #games
        #user periods

        PeriodUpdateJob.workSuspended = true
        PeriodUpdateJob.create {periodId:@period.id},
          error: logErrorResponse ""
          success: (model,response) =>
            @periodUpdateJob = model
            callback()

  tearDown: (callback) ->
    @period.destroy
      error: logErrorResponse ""
      success: =>
        #delete games
        #delete user periods
        return callback() unless @periodUpdateJob
        @periodUpdateJob.destroy
          error: logErrorResponse ""
          success: =>
            callback()

  periodUpdateJobWorkTest: (test) ->
    test.ok @period
    test.ok @period.id
    test.ok @periodUpdateJob
    test.ok @periodUpdateJob.id
    @periodUpdateJob.work
      error: logErrorResponse "periodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @periodUpdateJob.id
        test.done()