util = require "util"

couch = require "../lib/couch"
Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"
Period = models.Period
Game = models.Game
User = models.User
UserPeriod = models.UserPeriod

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob
UserPeriodUpdateJob = workers.UserPeriodUpdateJob


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createUserPeriodUpdateJob = 

  testCreateUserPeriodUpdateJob: (test) ->
    UserPeriodUpdateJob.workSuspended = true
    @userPeriodId = "xo1gqndsalnxkj"
    UserPeriodUpdateJob.create {userPeriodId:@userPeriodId},
      error: logErrorResponse ""
      success: (model,response) =>
        test.ok model
        test.equal model.get("doctype"), "UserPeriodUpdateJob"
        test.ok model.id
        @modelId = model.id
        test.equal model.get("userPeriodId"), @userPeriodId
        test.ok model.get("job")
        test.done()

  tearDown: (callback) ->
    j = new UserPeriodUpdateJob {id:@modelId}
    j.fetch
      error: logErrorResponse "j.fetch"
      success: ->
        j.destroy 
          error: logErrorResponse "j.destroy"
          success: -> callback()


exports.userPeriodUpdateJobQueries = 

  setUp: (callback) ->
    UserPeriodUpdateJob.workSuspended = true
    @userPeriodId = "xp2hrfiahlkjhs"
    UserPeriodUpdateJob.create {userPeriodId:@userPeriodId},
      error: logErrorResponse "UserPeriodUpdateJob.create"
      success: (model,_) => 
        @modelId = model.id
        callback()

  tearDown: (callback) ->
    j = new UserPeriodUpdateJob {id:@modelId}
    j.fetch
      error: logErrorResponse "tearDown fetch"
      success: ->
        j.destroy 
          error: logErrorResponse "tearDown destroy"
          success: -> callback()

  testUserPeriodUpdateJobCreatedDateView: (test) ->
    viewParams =
      startkey: ["UserPeriodUpdateJob",'1970-01-01T00:00:00.000Z']
      endKey: ["UserPeriodUpdateJob",'2070-01-01T00:00:00.000Z']
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
        test.equal job.id, @modelId, "expected model id"
        test.ok job.doc
        test.equal job.doc.userPeriodId, @userPeriodId, "no userPeriodId"
      test.done()

  testUserPeriodUpdateJobGetNext: (test) ->
    UserPeriodUpdateJob.getNext
      error: logErrorResponse ""
      success: (job,response) =>
        test.ok job
        test.equal job.id, @modelId
        test.equal job.get("userPeriodId"), @userPeriodId
        @userPeriodId2 = "dasbo4iqd289ihkj"
        UserPeriodUpdateJob.create {userPeriodId:@userPeriodId2},
          error: logErrorResponse "UserPeriodUpdateJob.create 2"
          success: (model2,_) => 
            test.ok model2
            test.equal model2.get("userPeriodId"),@userPeriodId2
            UserPeriodUpdateJob.getNext
              limit: 100
              error: logErrorResponse ""
              success: (jobs,response) =>
                test.ok jobs
                test.equal jobs.length,2
                test.equal jobs[0].get("userPeriodId"),@userPeriodId
                test.equal jobs[1].get("userPeriodId"),@userPeriodId2
                model2.destroy
                  error: logErrorResponse "model2.destroy"
                  success: => test.done()


exports.userPeriodUpdateJobWorkDeletedPeriod = 

  setUp: (callback) ->
    UserPeriodUpdateJob.workSuspended = true
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "@user.save"
      success: =>
        periodData = 
          league:
            statsKey: "alwhrnp98y2"
          category: "daily"
          startDate: new Date("Feb 11, 2010")
          endDate: new Date("Feb 12, 2010")
        periodData.id = Period.getCouchId
          category: periodData.category
          date: periodData.startDate
          leagueStatsKey: periodData.league.statsKey
        @period = new Period periodData
        @period.save @period.toJSON(),
          error: -> logErrorResponse
          success: (period,response) =>          
            UserPeriod.createForUserAndPeriod {userId:@user.id,periodId:@period.id},
              error: logErrorResponse "UserPeriod.createForUserAndPeriod"
              success: (userPeriod,response) =>
                @userPeriod = userPeriod
                UserPeriodUpdateJob.create {userPeriodId:@userPeriod.id},
                  error: logErrorResponse "UserPeriodUpdateJob.create"
                  success: (upuj,response) => 
                    @userPeriodUpdateJob = upuj
                    @period.destroy
                      error: logErrorResponse "@period.destroy"
                      success: => callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "@user.destroy"
      success: =>
        @userPeriodUpdateJob.destroy
          error: logErrorResponse "@userPeriodUpdateJob.destroy"
          success: => callback()

  userPeriodUpdateJobWorkDeletedPeriodTest: (test) ->
    test.ok @userPeriod.id
    test.ok @userPeriodUpdateJob.id
    @userPeriodUpdateJob.work
      error: logErrorResponse "userPeriodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @userPeriodUpdateJob.id, "oioioi"
        userPeriod = new UserPeriod {id:@userPeriod.id}
        userPeriod.fetch
          success: => console.log "not what we expect!"
          error: (_,response) =>
            test.equal response.status_code,404,"userPeriod should be gone"
            test.done()
