util = require "util"

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

workers = require "../lib/workers"
PeriodUpdateJob = workers.PeriodUpdateJob
PeriodUpdateJob.workSuspended = true

gameUpdater = require "../lib/game-updater"


logErrorResponse = (model,response) ->
  console.log "response: #{require('util').inspect response}"


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
      test.equal model.id, "sdfgn128o7nz"
      test.done()


exports.testGamePost = (test) ->
  data = 
    statsKey: "9128b89e7g12qwiuexbqiuwbe128"
    updated_at: 1338482433
    league: "MLB"
    leagueStatsKey: "1028ei1e2nhiouznhn1z2"
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
  x.on 'success', (response) ->
    test.equal response.status,201
    test.equal response.body.doctype,"Game"
    test.equal response.body.statsKey,data.statsKey
    test.equal response.body.statsLatestUpdateDate,(new Date(data.updated_at*1000)).toJSON()
    test.equal response.body.league.abbreviation,data.league
    test.equal response.body.league.statsKey,data.leagueStatsKey
    test.equal response.body.awayTeam.statsKey,data.away_team.key
    test.equal response.body.awayTeam.location,data.away_team.location
    test.equal response.body.awayTeam.name,data.away_team.name
    test.equal response.body.homeTeam.statsKey,data.home_team.key
    test.equal response.body.homeTeam.location,data.home_team.location
    test.equal response.body.homeTeam.name,data.home_team.name
    test.equal response.body.startDate,(new Date(data.starts_at*1000)).toJSON()
    test.equal response.body.status.score.away,data.away_score
    test.equal response.body.status.score.home,data.home_score
    test.equal response.body.status.text,data.status
    test.equal response.body.status.final,data.final
    test.equal response.body.legit,data.legit
    test.equal response.body.pickCount.home,null
    test.equal response.body.pickCount.away,null
    test.equal response.body.pickCount.draw,null
    test.ok response.body.id
    PeriodUpdateJob.getNext
      limit: 2
      error: logErrorResponse
      success: (jobs,_) ->
        test.ok jobs
        test.equal jobs.length, 1, "should create 1 PeriodUpdateJob"
        test.equal jobs[0].get("league").statsKey,data.leagueStatsKey
        test.ok jobs[0].id
        jobs[0].destroy
          error: logErrorResponse
          success: ->
            g = new Game({id:response.body.id})
            g.fetch
              error: logErrorResponse
              success: (model,response) ->
                model.destroy
                  error: logErrorResponse
                  success: -> test.done()


exports.testGamePostUpdate =

  setUp: (callback) ->
    @gameData =
      statsKey: 'nrx1nx1rn89n1n89r1'
      id: 'game_nrx1nx1rn89n1n89r1'
      statsLatestUpdateDate: new Date(2010,1,1)
      league: 
        abbreviation: 'MLB'
        statsKey: 'r1373r782'
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
      basePeriodKey: "o2enx1khad89"
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
          success: -> callback()

  testGamePostUpdate: (test) ->
    data = 
      statsKey: @gameData.statsKey
      updated_at: (new Date(2010,1,2)).valueOf()/1000
      league: "MLB"
      leagueStatsKey: "r1373r782"
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
      test.equal response.body.doctype,"Game"
      test.equal response.body.statsKey,data.statsKey
      test.equal response.body.statsLatestUpdateDate,(new Date(data.updated_at*1000)).toJSON()
      test.equal response.body.league.abbreviation,data.league
      test.equal response.body.league.statsKey,data.leagueStatsKey
      test.equal response.body.awayTeam.statsKey,data.away_team.key
      test.equal response.body.awayTeam.location,data.away_team.location
      test.equal response.body.awayTeam.name,data.away_team.name
      test.equal response.body.homeTeam.statsKey,data.home_team.key
      test.equal response.body.homeTeam.location,data.home_team.location
      test.equal response.body.homeTeam.name,data.home_team.name
      test.equal response.body.startDate,(new Date(data.starts_at*1000)).toJSON()
      test.equal response.body.status.score.away,data.away_score
      test.equal response.body.status.score.home,data.home_score
      test.equal response.body.status.text,data.status
      test.equal response.body.status.final,data.final
      test.equal response.body.legit,data.legit
      test.equal response.body.pickCount.home,@gameData.pickCount.home
      test.equal response.body.pickCount.away,@gameData.pickCount.away
      test.equal response.body.pickCount.draw,@gameData.pickCount.draw
      test.ok response.body.id
      test.ok response.body.basePeriodKey 
      PeriodUpdateJob.getNext
        limit: 2
        error: logErrorResponse
        success: (jobs,_) ->
          test.ok jobs
          test.equal jobs.length, 1, "should create 1 PeriodUpdateJob"
          test.equal jobs[0].get("league").statsKey,data.leagueStatsKey
          test.ok jobs[0].id
          jobs[0].destroy
            error: logErrorResponse
            success: ->
              test.done()


exports.couchViewForGamesByLeagueAndStartDate = (test) ->
  leagueStatsKey = "dqxugoqd7ngauidgas"
  startDate = new Date(2012,1,1)
  gameDate = new Date(2012,1,1,12,30)
  endDate = new Date(2012,1,2)
  laterGameDate = new Date(2012,1,2,12,30)
  viewParams =
    startkey: [leagueStatsKey,startDate.toJSON()]
    endkey: [leagueStatsKey,endDate.toJSON()]
    include_docs: true
  couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
    test.ok !err
    test.ok body
    test.ok body.rows
    test.equal body.rows.length,0
    g = new Game
      league:
        statsKey: leagueStatsKey
      startDate: gameDate
    g.save g.toJSON(),
      error: logErrorResponse
      success: (model,response) ->
        test.ok model
        test.ok model.id
        test.equal model.get("league").statsKey,leagueStatsKey
        test.equal model.get("startDate").toJSON(),gameDate.toJSON()
        viewParams =
          startkey: [leagueStatsKey,startDate.toJSON()]
          endkey: [leagueStatsKey,endDate.toJSON()]
          include_docs: true
        couch.db.view "games","byLeagueAndStartDate", viewParams, (err,body,headers) ->
          test.ok !err
          test.ok body
          test.ok body.rows
          test.equal body.rows.length, 1
          test.ok body.rows[0].doc  
          test.equal body.rows[0].doc._id, model.id
          test.equal body.rows[0].doc.league.statsKey, leagueStatsKey
          test.equal body.rows[0].doc.startDate, gameDate.toJSON()
          gB = new Game
            league:
              statsKey: leagueStatsKey
            startDate: laterGameDate
          gB.save gB.toJSON(),
            error: logErrorResponse
            success: (modelB,response) ->
              test.ok modelB
              test.ok modelB.id
              test.equal modelB.get("league").statsKey,leagueStatsKey
              test.equal modelB.get("startDate").toJSON(),laterGameDate.toJSON()
              viewParams =
                startkey: [leagueStatsKey,startDate.toJSON()]
                endkey: [leagueStatsKey,endDate.toJSON()]
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
                      success: -> test.done()

