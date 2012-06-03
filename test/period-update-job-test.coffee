util = require "util"

couch = require "../lib/couch"
Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "#{message}-> response: #{util.inspect response}"


exports.createPeriodUpdateJob = 

  testCreatePeriodUpdateJob: (test) ->
    @periodId = "nlxuiqnonorq2rq2"
    PeriodUpdateJob.create {periodId:@periodId},
      error: logErrorResponse
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
      error: logErrorResponse
      success: ->
        j.destroy 
          error: logErrorResponse
          success: -> callback()


exports.periodUpdateJobQueries = 

  setUp: (callback) ->
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
      error: logErrorResponse
      success: (job,response) =>
        test.ok job
        test.equal job.id, @modelId
        test.equal job.get("periodId"), @periodId
        test.done()