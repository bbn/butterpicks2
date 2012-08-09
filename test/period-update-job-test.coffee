csrequire = require('covershot').require.bind(null, require)

util = require "util"

couch = csrequire "../lib/couch"
Backbone = require "backbone"
bbCouch = csrequire "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = csrequire "../lib/models"
csrequire "../lib/model-server-utils"
Period = models.Period
League = models.League
Game = models.Game
User = models.User
UserPeriod = models.UserPeriod

workers = csrequire "../lib/workers"
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
        p = new Period(@periodData)
        p.save p.toJSON(),
          error: -> logErrorResponse "p.save"
          success: (model,response) =>
            @period = model
            PeriodUpdateJob.workSuspended = true
            PeriodUpdateJob.create {periodId:@period.id},
              error: logErrorResponse "PeriodUpdateJob.create"
              success: (model,response) =>
                @periodUpdateJob = model
                callback()

  tearDown: (callback) ->
    @periodUpdateJob.destroy
      error: logErrorResponse "periodUpdateJob.destroy"
      success: =>
        @league.destroy
          success: =>
            callback()


  periodUpdateJobWorkDeleteTest: (test) ->
    test.ok @period
    test.ok @period.id
    test.ok @periodUpdateJob
    test.ok @periodUpdateJob.id
    UserPeriodUpdateJob.workSuspended = true
    @periodUpdateJob.work
      error: logErrorResponse "periodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @periodUpdateJob.id
        @period.fetch
          success: logErrorResponse "unexpected!"
          error: (_,response) =>
            test.equal response.status_code,404
            test.done()



  periodUpdateJobWorkUpdateTest: (test) ->
    test.ok @period
    test.ok @period.id
    test.ok @periodUpdateJob
    test.ok @periodUpdateJob.id
    UserPeriodUpdateJob.workSuspended = true
    @gameData =
      statsKey: 'u1t2fhlajskhckjash'
      id: 'game_u1t2fhlajskhckjash'
      statsLatestUpdateDate: new Date("Jan 1, 2011, 13:00")
      leagueId: @league.id
      awayTeam: 
        statsKey: '1267bidwyqugksa'
        location: 'Chicago'
        name: 'Cubs'
      homeTeam: 
        statsKey: '127o8qgulbja'
        location: 'Boston'
        name: 'Red Sox'
      startDate: new Date("Jan 1, 2011, 12:00")
      status:
        score: 
          home: 72
          away: 1
        text: '2nd inning'
        final: false
      legit: true
      pickCount:
        home: 2536
        away: 1234
        draw: null
    @game = new Game(@gameData)
    @game.save @game.toJSON(),
      error: logErrorResponse "@game.save"
      success: =>
        user = new User()
        user.save user.toJSON(),
          error: logErrorResponse "user.save"
          success: (user,response) =>
            UserPeriod.createForUserAndPeriod {userId:user.id,periodId:@period.id},
              error: logErrorResponse "UserPeriod.createForUserAndPeriod"
              success: (userPeriod,response) =>
                @periodUpdateJob.work
                  error: logErrorResponse "@periodUpdateJob.work"
                  success: (model,response) =>
                    test.equal model.id, @periodUpdateJob.id
                    @period.fetch
                      error: logErrorResponse "@period.fetch"
                      success: =>
                        test.ok @period.id
                        test.equal @period.get("final"),false
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
                                      error: logErrorResponse "userPeriod.destroy"
                                      success: =>
                                        user.destroy
                                          error: logErrorResponse "user.destroy"
                                          success: =>
                                            @game.destroy
                                              error: logErrorResponse "@game.destroy"
                                              success: =>
                                                @period.destroy
                                                  error: logErrorResponse "@period.destroy"
                                                  success: =>
                                                    test.done()