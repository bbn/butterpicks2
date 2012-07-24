util = require "util"
require "../lib/date"

journey = require "journey"
controllers = require "../lib/controllers"
mockRequest = require "../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
journey.env = "test"

couch = require "../lib/couch"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
Game = models.Game
League = models.League

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob
PeriodUpdateJob.workSuspended = true

gameUpdater = require "../lib/game-updater"


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "#{message} -> response: #{require('util').inspect response}"


exports.couchViewForMostRecentlyUpdatedGame = (test) ->
  gameUpdater.getMostRecentlyUpdatedGameDate
    error: logErrorResponse
    success: (d0,response) ->
      test.equal d0,null,"date should be null. #{d0}"
      g = new Game
        statsKey: "sahgdjhagsjd281"
        statsLatestUpdateDate: new Date("Jan 1 2000")
      g.save g.toJSON(),
        error: logErrorResponse
        success: (model,response) ->
          test.ok model
          test.ok model.id
          gameUpdater.getMostRecentlyUpdatedGameDate
            error: logErrorResponse
            success: (d1,response) ->
              test.ok d1
              test.equal d1.toJSON(), model.get("statsLatestUpdateDate").toJSON()
              g2 = new Game
                statsKey: "1zg8z1sg8"
                statsLatestUpdateDate: new Date("Feb 1 2000")
              g2.save g2.toJSON(),
                error: logErrorResponse
                success: (model2,response) ->
                  test.ok model2
                  test.ok model2.id
                  gameUpdater.getMostRecentlyUpdatedGameDate
                    error: logErrorResponse
                    success: (d2,response) ->
                      test.ok d2
                      test.equal d2.toJSON(), model2.get("statsLatestUpdateDate").toJSON()
                      #cleanup
                      model.destroy
                        error: logErrorResponse
                        success: ->
                          model2.destroy
                            error: logErrorResponse
                            success: -> test.done()


exports.testFetchingMissingGame = (test) ->
  g = new Game({ id: "sdfgn128o7nz"})
  g.fetch
    success: logErrorResponse
    error: (model,response) ->
      test.equal response.status_code, 404, "expect 404"
      test.equal response.error, 'not_found', "expect not_found"
      test.ok model
      test.equal model.get("id"), "sdfgn128o7nz"
      test.done()


exports.testGamePost = 

  setUp: (callback) ->
    @leagueStatsKey = "9128b89e7g12qwiuexbqiuwbe128"
    league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    league.save league.toJSON(),
      error: logErrorResponse "setUp"
      success: (league,response) =>
        @league = league
        callback()

  tearDown: (callback) ->
    @league.destroy
      error: logErrorResponse "@league.destroy"
      success: -> callback()

  testGamePost: (test) ->
    data = 
      statsKey: @leagueStatsKey
      updated_at: 1338482433
      league: "MLB"
      leagueStatsKey: @leagueStatsKey
      away_team:
        key: "7v8tfgy9humi"
        location: "Chicago"
        name: "Cubs"
      home_team:
        key: "u1zdhqlkajshd"
        location: "Boston"
        name: "Red Sox"
      starts_at: 1338482480
      away_score: 7
      home_score: 2
      status: "7th inning"
      final: false
      legit: true
    x = mock.post "/game", { accept: "application/json" }, JSON.stringify data
    x.on 'success', (response) =>
      test.equal response.status,201
      test.ok response.body
      gameData = response.body
      test.equal gameData.doctype,"Game"
      test.equal gameData.statsKey,data.statsKey
      test.equal gameData.statsLatestUpdateDate,(new Date(data.updated_at*1000)).toJSON()
      test.equal gameData.leagueId,@league.id
      test.equal gameData.awayTeam.statsKey,data.away_team.key
      test.equal gameData.awayTeam.location,data.away_team.location
      test.equal gameData.awayTeam.name,data.away_team.name
      test.equal gameData.homeTeam.statsKey,data.home_team.key
      test.equal gameData.homeTeam.location,data.home_team.location
      test.equal gameData.homeTeam.name,data.home_team.name
      test.equal gameData.startDate,(new Date(data.starts_at*1000)).toJSON()
      test.equal gameData.status.score.away,data.away_score
      test.equal gameData.status.score.home,data.home_score
      test.equal gameData.status.text,data.status
      test.equal gameData.status.final,data.final
      test.equal gameData.legit,data.legit
      test.equal gameData.pickCount.home,0
      test.equal gameData.pickCount.away,0
      test.equal gameData.pickCount.draw,0
      test.ok gameData.id
      PeriodUpdateJob.getNext
        limit: 2
        error: logErrorResponse
        success: (jobs,_) =>
          test.ok jobs
          test.equal jobs.length, 1, "should create 1 PeriodUpdateJob"
          test.equal jobs[0].get("leagueId"),@league.id
          test.ok jobs[0].id
          jobs[0].destroy
            error: logErrorResponse
            success: ->
              g = new Game({id:gameData.id})
              g.fetch
                error: logErrorResponse
                success: (model,response) ->
                  model.destroy
                    error: logErrorResponse
                    success: -> test.done()


exports.testGamePostUpdate =

  setUp: (callback) ->
    @leagueStatsKey = "9128b89e7g12qwiuexbqiuwbe128"
    league = new League
      statsKey: @leagueStatsKey
      basePeriodCategory: "daily"
    league.save league.toJSON(),
      error: logErrorResponse "setUp"
      success: (league,response) =>
        @league = league
        @gameData =
          statsKey: 'nrx1nx1rn89n1n89r1'
          id: 'game_nrx1nx1rn89n1n89r1'
          statsLatestUpdateDate: new Date(2010,1,1)
          leagueId: @league.id
          awayTeam: 
            statsKey: 'xn893rpiqu3hni'
            location: 'Chicago'
            name: 'Cubs'
          homeTeam: 
            statsKey: '78oniuynoiuy'
            location: 'Boston'
            name: 'Red Sox'
          startDate: new Date(2010,2,2)
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
        g = new Game(@gameData)
        g.save g.toJSON(),
          error: logErrorResponse
          success: (model,response) =>
            @model = model
            callback()

  tearDown: (callback) ->
    return callback() unless @model
    @model.fetch
      error: logErrorResponse
      success: =>
        @model.destroy
          error: logErrorResponse
          success: => 
            @league.destroy
              error: logErrorResponse
              success: -> callback()

  testGamePostUpdate: (test) ->
    data = 
      statsKey: @gameData.statsKey
      updated_at: (new Date(2010,1,2)).valueOf()/1000
      league: "MLB"
      leagueStatsKey: @league.get "statsKey"
      away_team:
        key: "xn893rpiqu3hni"
        location: "Chicago"
        name: "Cubs"
      home_team:
        key: "78oniuynoiuy"
        location: "Boston"
        name: "Red Sox"
      starts_at: (new Date(2010,2,2)).valueOf()/1000
      away_score: 72
      home_score: 2
      status: "7th inning"
      final: false
      legit: true
    x = mock.post "/game", { accept: "application/json" }, JSON.stringify data
    x.on 'success', (response) =>
      test.equal response.status,201
      test.ok response.body
      gameData = response.body
      test.equal gameData.doctype,"Game"
      test.equal gameData.statsKey,data.statsKey
      test.equal gameData.statsLatestUpdateDate,(new Date(data.updated_at*1000)).toJSON()
      test.equal gameData.leagueId,@league.id
      test.equal gameData.awayTeam.statsKey,data.away_team.key
      test.equal gameData.awayTeam.location,data.away_team.location
      test.equal gameData.awayTeam.name,data.away_team.name
      test.equal gameData.homeTeam.statsKey,data.home_team.key
      test.equal gameData.homeTeam.location,data.home_team.location
      test.equal gameData.homeTeam.name,data.home_team.name
      test.equal gameData.startDate,(new Date(data.starts_at*1000)).toJSON()
      test.equal gameData.status.score.away,data.away_score
      test.equal gameData.status.score.home,data.home_score
      test.equal gameData.status.text,data.status
      test.equal gameData.status.final,data.final
      test.equal gameData.legit,data.legit
      test.equal gameData.pickCount.home,@gameData.pickCount.home
      test.equal gameData.pickCount.away,@gameData.pickCount.away
      test.equal gameData.pickCount.draw,@gameData.pickCount.draw
      test.ok gameData.id
      PeriodUpdateJob.getNext
        limit: 2
        error: logErrorResponse
        success: (jobs,_) =>
          test.ok jobs
          test.equal jobs.length, 1, "should create 1 PeriodUpdateJob"
          test.equal jobs[0].get("leagueId"),@league.id
          test.ok jobs[0].id
          jobs[0].destroy
            error: logErrorResponse
            success: ->
              test.done()

  testGamePostUpdateToDifferentPeriod: (test) ->
    data = 
      statsKey: @gameData.statsKey
      updated_at: (new Date(2010,1,2)).valueOf()/1000
      league: "MLB"
      leagueStatsKey: @league.get "statsKey"
      away_team:
        key: "xn893rpiqu3hni"
        location: "Chicago"
        name: "Cubs"
      home_team:
        key: "78oniuynoiuy"
        location: "Boston"
        name: "Red Sox"
      starts_at: (new Date(2010,2,3)).valueOf()/1000
      away_score: 72
      home_score: 1
      status: "2nd inning"
      final: false
      legit: true
    x = mock.post "/game", { accept: "application/json" }, JSON.stringify data
    x.on 'success', (response) =>
      test.equal response.status,201
      test.ok response.body
      gameData = response.body
      test.equal gameData.doctype,"Game"
      test.equal gameData.statsKey,data.statsKey
      test.equal gameData.statsLatestUpdateDate,(new Date(data.updated_at*1000)).toJSON()
      test.equal gameData.leagueId,@league.id
      test.equal gameData.awayTeam.statsKey,data.away_team.key
      test.equal gameData.awayTeam.location,data.away_team.location
      test.equal gameData.awayTeam.name,data.away_team.name
      test.equal gameData.homeTeam.statsKey,data.home_team.key
      test.equal gameData.homeTeam.location,data.home_team.location
      test.equal gameData.homeTeam.name,data.home_team.name
      test.equal gameData.startDate,(new Date(data.starts_at*1000)).toJSON()
      test.equal gameData.status.score.away,data.away_score
      test.equal gameData.status.score.home,data.home_score
      test.equal gameData.status.text,data.status
      test.equal gameData.status.final,data.final
      test.equal gameData.legit,data.legit
      test.equal gameData.pickCount.home,@gameData.pickCount.home
      test.equal gameData.pickCount.away,@gameData.pickCount.away
      test.equal gameData.pickCount.draw,@gameData.pickCount.draw
      test.ok gameData.id
      PeriodUpdateJob.getNext
        limit: 2
        error: logErrorResponse
        success: (jobs,_) =>
          test.ok jobs
          test.equal jobs.length, 2, "should create 2 PeriodUpdateJobs"
          jobs[0].destroy
            success: -> jobs[1].destroy
              success: ->
                test.done()



exports.couchViewForGamesByLeagueAndStartDate = (test) ->
  leagueStatsKey = "dqxugoqd7ngauidgas"
  league = new League
    statsKey: leagueStatsKey
    basePeriodCategory: "daily"
  league.save league.toJSON(),
    error: logErrorResponse "league.save"
    success: (model,response) =>
      startDate = new Date(2012,1,1)
      gameDate = new Date(2012,1,1,12,30)
      endDate = new Date(2012,1,2)
      laterGameDate = new Date(2012,1,2,12,30)
      viewParams =
        startkey: [league.id,startDate.toJSON()]
        endkey: [league.id,endDate.toJSON()]
        include_docs: true
      couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
        test.ok !err
        test.ok body
        test.ok body.rows
        test.equal body.rows.length,0
        g = new Game
          leagueId: league.id
          startDate: gameDate
        g.save g.toJSON(),
          error: logErrorResponse
          success: (model,response) ->
            test.ok model
            test.ok model.id
            test.equal model.get("leagueId"),league.id
            test.equal model.get("startDate").toJSON(),gameDate.toJSON()
            viewParams =
              startkey: [league.id,startDate.toJSON()]
              endkey: [league.id,endDate.toJSON()]
              include_docs: true
            couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
              test.ok !err
              test.ok body
              test.ok body.rows
              test.equal body.rows.length, 1
              test.ok body.rows[0].doc
              test.equal body.rows[0].doc._id, model.id
              test.equal body.rows[0].doc.leagueId, league.id
              test.equal body.rows[0].doc.startDate, gameDate.toJSON()
              gB = new Game
                leagueId: league.id
                startDate: laterGameDate
              gB.save gB.toJSON(),
                error: logErrorResponse
                success: (modelB,response) ->
                  test.ok modelB
                  test.ok modelB.id
                  test.equal modelB.get("leagueId"),league.id
                  test.equal modelB.get("startDate").toJSON(),laterGameDate.toJSON()
                  viewParams =
                    startkey: [league.id,startDate.toJSON()]
                    endkey: [league.id,endDate.toJSON()]
                    include_docs: true
                  couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
                    test.ok !err
                    test.ok body
                    test.ok body.rows
                    test.equal body.rows.length, 1, "should only pick up first game"
                    test.ok body.rows[0].doc  
                    test.equal body.rows[0].doc._id, model.id, "1st game, not 2nd"
                    modelB.destroy
                      error: logErrorResponse
                      success: ->
                        model.destroy
                          error: logErrorResponse
                          success: -> 
                            league.destroy
                              error: logErrorResponse
                              success: -> test.done()


exports.gameModelTest = (test) ->
  now = new Date()
  earlierDate = (new Date(now)).add {hours:-1}
  g = new Game
    startDate: earlierDate
  test.ok (g.secondsUntilDeadline() + 60*60) <= 0
  test.ok (g.secondsUntilDeadline() + (60*60+1)) > 0
  test.equal g.deadlineHasPassed(), true
  test.equal g.postponed(), false
  test.equal g.homeWin(), null
  test.equal g.awayWin(), null
  test.equal g.draw(), null
  g.set { status: { text: "postponed"}}
  test.equal g.postponed(), true
  g.set
    status:
      final: true
      score:
        home: 3
        away: 1
  test.equal g.postponed(),false
  test.equal g.homeWin(),true
  test.equal g.awayWin(),false
  test.equal g.draw(),null
  g.set
    status:
      final: true
      score:
        home: 3
        away: 22
  test.equal g.homeWin(),false
  test.equal g.awayWin(),true
  test.equal g.draw(),null
  g.set
    couldDraw: true
  test.equal g.draw(),false
  g.set
    status:
      final: true
      score:
        home: 1
        away: 1
  test.equal g.draw(),true
  test.equal g.homeWin(),false
  test.equal g.awayWin(),false
  test.done()


