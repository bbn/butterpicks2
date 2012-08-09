csrequire = require('covershot').require.bind(null, require)

util = require "util"

couch = csrequire "../lib/couch"
Backbone = require "backbone"
bbCouch = csrequire "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = csrequire "../lib/models"
csrequire "../lib/model-server-utils"
User = models.User
Game = models.Game
Pick = models.Pick
Period = models.Period
UserPeriod = models.UserPeriod
League = models.League

workers = csrequire "../lib/workers"
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
    j = new UserPeriodUpdateJob {_id:@modelId}
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
    j = new UserPeriodUpdateJob {_id:@modelId}
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
        @league = new League
          statsKey: "8172obdlxiuegldaigsubdliu"
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: =>
            periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Feb 11, 2010")
              endDate: new Date("Feb 12, 2010")
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
          success: => 
            @league.destroy
              error: logErrorResponse "@league.destroy"
              success: =>
                callback()

  userPeriodUpdateJobWorkDeletedPeriodTest: (test) ->
    test.ok @userPeriod.id
    test.ok @userPeriodUpdateJob.id
    @userPeriodUpdateJob.work
      error: logErrorResponse "userPeriodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @userPeriodUpdateJob.id, "oioioi"
        userPeriod = new UserPeriod {_id:@userPeriod.id}
        userPeriod.fetch
          success: => console.log "not what we expect!"
          error: (_,response) =>
            test.equal response.status_code,404,"userPeriod should be gone"
            test.done()


exports.userPeriodUpdateJobWorkUpdatePoints = 

  setUp: (callback) ->
    UserPeriodUpdateJob.workSuspended = true
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "@user.save"
      success: =>
        @league = new League
          statsKey: "xhi3hf3fln389"
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: =>
            periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Feb 11, 2010")
              endDate: new Date("Feb 12, 2010")
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
                        @game1 = new Game
                          statsKey: "daos8xliu"
                          leagueId: @league.id
                          awayTeam:
                            statsKey: "12dsklalds"
                          homeTeam:
                            statsKey: "asjklhnp928x"
                          startDate: @period.get("startDate").add({hours:1})
                          status:
                            score:
                              away: 1
                              home: 0
                            text: "final"
                            final: true
                          pickCount:
                            home: 100
                            away: 50
                            draw: 0
                        @game1.save @game1.toJSON(),
                          error: logErrorResponse "game1.save"
                          success: (game1) =>
                            Pick.create
                              userId: @user.id
                              gameId: @game1.id
                              home: false
                              away: true
                              draw: false
                              butter: false
                              createdDate: new Date("Feb 9, 2010")
                              updatedDate: new Date("Feb 9, 2010")
                              success: (pick1) =>
                                @pick1 = pick1
                                callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "@user.destroy"
      success: =>
        @userPeriodUpdateJob.destroy
          error: logErrorResponse "@userPeriodUpdateJob.destroy"
          success: => 
            @league.destroy
              error: logErrorResponse "@league.destroy"
              success: =>
                @game1.destroy
                  success: =>
                    @pick1.destroy
                      success: =>                          
                        @userPeriod.fetch
                          error: logErrorResponse "@userPeriod.fetch"
                          success: (userPeriod) =>
                            userPeriod.destroy
                              error: logErrorResponse "@userPeriod.destroy"
                              success: =>
                                @period.destroy
                                  success: =>
                                    callback()

  userPeriodUpdateJobWorkDeletedPeriodTest: (test) ->
    test.ok @userPeriod.id
    test.ok @userPeriodUpdateJob.id
    @userPeriodUpdateJob.work
      error: logErrorResponse "userPeriodUpdateJob.work error"
      success: (model,response) =>
        test.equal model.id, @userPeriodUpdateJob.id, "oioioi"
        userPeriod = new UserPeriod {_id:@userPeriod.id}
        userPeriod.fetch
          error: logErrorResponse "userPeriod.fetch"
          success: (userPeriod) =>
            test.ok userPeriod
            test.equal userPeriod.id, @userPeriod.id
            test.equal userPeriod.get("metrics").points, 100
            game2 = new Game
              statsKey: "rdvftyguhijk"
              leagueId: @league.id
              awayTeam:
                statsKey: "w45rtdguligkhj"
              homeTeam:
                statsKey: "rue5r6ituigh"
              startDate: @period.get("startDate").add({hours:3})
              status:
                score:
                  home: 3
                  away: 1
                text: "3rd period"
                final: false
              pickCount:
                home: 33
                away: 66
                draw: 0
            game2.save game2.toJSON(),
              error: logErrorResponse "game2.save"
              success: (game2) =>
                test.ok game2.id
                Pick.create
                  userId: @user.id
                  gameId: game2.id
                  home: true
                  away: false
                  draw: false
                  butter: false
                  createdDate: new Date("Feb 7, 2010")
                  updatedDate: new Date("Feb 8, 2010")
                  success: (pick2) =>
                    test.ok pick2.id
                    @userPeriodUpdateJob.work
                      error: logErrorResponse "userPeriodUpdateJob.work 2 error"
                      success: (model,response) =>
                        test.equal model.id, @userPeriodUpdateJob.id
                        @userPeriod.fetch
                          error: logErrorResponse "@userPeriod.fetch"
                          success: (userPeriod) =>
                            test.ok userPeriod
                            test.equal userPeriod.id, @userPeriod.id
                            test.equal userPeriod.get("metrics").points, 100
                            pick2.destroy
                              success: => game2.destroy
                                success: =>
                                  test.done()
