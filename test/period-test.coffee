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
      error: -> console.log "huh?"
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
