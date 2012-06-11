util = require "util"

journey = require "journey"
controllers = require "../lib/controllers"
mockRequest = require "../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
journey.env = "test"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

Period = models.Period
Game = models.Game

require "../lib/date"


logErrorResponse = (model,response) ->
  console.log "response: #{require('util').inspect response}"


exports.testGetDailyPeriod =

  setUp: (callback) ->
    @periodData = 
      league:
        statsKey: "dskaljdlkskldjaslkjdlaskjd"
      category: "daily"
      startDate: new Date("Jan 1, 2010")
      endDate: new Date("Jan 2, 2010")
    d = @periodData.startDate
    dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
    @periodData.id = "#{@periodData.league.statsKey}_#{@periodData.category}_#{dateString}"
    p = new Period(@periodData)
    p.save p.toJSON(),
      error: -> console.log "error saving Period"
      success: (model,response) =>
        @period = model
        callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: -> logErrorResponse
      success: -> callback()

  testGetDailyPeriod: (test) ->
    test.ok @period, "cached model is ok"
    category = @periodData.category
    leagueStatsKey = @periodData.league.statsKey
    d = @periodData.startDate
    dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
    url = "/period?category=#{category}&leagueStatsKey=#{leagueStatsKey}&date=#{dateString}"
    x = mock.get url, { accept: "application/json" }
    x.on "success", (response) =>
      test.ok response, "response is ok"
      test.equal response.body.error,null,"error should be null: #{util.inspect response.body.error}"
      test.equal response.status, 200, "status should be 200"
      test.equal response.body.id, @periodData.id
      test.ok response.body.league
      test.equal response.body.league.statsKey,@periodData.league.statsKey
      test.equal response.body.category,@periodData.category
      test.equal response.body.startDate, @periodData.startDate.toJSON()
      test.equal response.body.endDate, @periodData.endDate.toJSON()
      test.done()


exports.testFetchGames = 

  setUp: (callback) ->
    @periodData = 
      league:
        statsKey: "o89xn3oiuqndjklwhank"
      category: "daily"
      startDate: new Date("Jan 11, 2010")
      endDate: new Date("Jan 12, 2010")
    @periodData.id = Period.getCouchId
      category: @periodData.category
      date: @periodData.startDate
      leagueStatsKey: @periodData.league.statsKey
    p = new Period(@periodData)
    p.save p.toJSON(),
      error: -> logErrorResponse
      success: (model,response) =>
        @period = model
        callback()

  tearDown: (callback) ->
    return callback() unless @period
    @period.destroy
      error: -> logErrorResponse
      success: -> callback()

  testFetchGames: (test) ->
    test.ok @period
    @period.fetchGames
      error: logErrorResponse
      success: (games,response) =>
        test.equal games.length,0
        g1 = new Game
          league:
            statsKey: @periodData.league.statsKey
          startDate: (new Date(@periodData.startDate)).addHours(1)
        g1.save g1.toJSON(),
          error: logErrorResponse
          success: (game1,response) =>
            test.ok game1
            test.ok game1.id
            @period.fetchGames
              error: logErrorResponse
              success: (games,response) =>
                test.equal games.length,1
                test.ok games[0].id
                test.equal games[0].id, game1.id
                g2 = new Game
                  league:
                    statsKey: @periodData.league.statsKey
                  startDate: new Date(2010,1,16,17,00)
                g2.save g2.toJSON(),
                  error: logErrorResponse
                  success: (game2,response) =>
                    test.ok game2
                    @period.fetchGames
                      error: logErrorResponse
                      success: (games,response) =>
                        test.equal games.length,1,"should be 1 game only"
                        test.equal games[0].id,game1.id,"should be 1st game"
                        game2.destroy
                          error: logErrorResponse
                          success: =>
                            test.done()
                            game1.destroy
                              error: logErrorResponse
                              success: =>
                                test.done()

  testFetchUserPeriods: (test) ->
    test.ok false, "implement testFetchUserPeriods"
    test.done()