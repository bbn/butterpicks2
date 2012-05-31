util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

Game = models.Game

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
              test.equal JSON.stringify(d1), JSON.stringify(model.get("statsLatestUpdateDate")), "dates the same"
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
                      test.equal JSON.stringify(d2), JSON.stringify(model2.get("statsLatestUpdateDate")), "dates2 the same"
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