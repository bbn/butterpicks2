util = require "util"

couch = require "../lib/couch"
Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"
Period = models.Period
League = models.League
Game = models.Game
User = models.User
UserPeriod = models.UserPeriod

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob
UserPeriodUpdateJob = workers.UserPeriodUpdateJob


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
    @league = new League
      statsKey: "ox8r1diqsaknxkfu"
      basePeriodCategory: "daily"
    @league.save @league.toJSON(),
      error: logErrorResponse "@league.save"
      success: =>
        @periodData = 
          leagueId: @league.id
          category: @league.get "basePeriodCategory"
          startDate: new Date("Jan 1, 2011")
          endDate: new Date("Jan 2, 2011")
        @periodData.id = Period.getCouchId
          leagueId: @league.id
          category: @periodData.category
          date: @periodData.startDate
        p = new Period(@periodData)
        p.save p.toJSON(),
          error: -> logErrorResponse "p.save"
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
            @league.destroy
              success: =>
                callback()

  periodUpdateJobWorkTest: (test) ->
    test.ok @period
    test.ok @period.id
    test.ok @periodUpdateJob
    test.ok @periodUpdateJob.id
    UserPeriodUpdateJob.workSuspended = true
    @periodUpdateJob.work
      error: logErrorResponse "periodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @periodUpdateJob.id
        user = new User()
        user.save user.toJSON(),
          error: logErrorResponse "user.save"
          success: (user,response) =>
            UserPeriod.createForUserAndPeriod {userId:user.id,periodId:@period.id},
              error: logErrorResponse "UserPeriod.createForUserAndPeriod"
              success: (userPeriod,response) =>
                @periodUpdateJob.work
                  error: logErrorResponse "periodUpdateJob.work 2 error"
                  success: (model,response) =>
                    test.equal model.id, @periodUpdateJob.id
                    UserPeriodUpdateJob.getNext
                      error: logErrorResponse "UserPeriodUpdateJob.getNext"
                      success: (job,response) =>
                        test.ok job
                        job.destroy
                          error: logErrorResponse "deleting UserPeriodUpdateJob"
                          success: =>
                            UserPeriodUpdateJob.getNext
                              error: logErrorResponse "UserPeriodUpdateJob.getNext 2"
                              success: (job,response) =>
                                test.equal job,null,"all jobs deleted"
                                userPeriod.destroy
                                  error: logErrorResponse
                                  success: =>
                                    user.destroy
                                      error: logErrorResponse "user.destroy"
                                      success: =>
                                        test.done()