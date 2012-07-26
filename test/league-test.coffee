util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"

League = models.League

logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createLeague = 

  testCreateLeague: (test) ->
    attributes =
      statsKey: "axo87npiusnakhniu"
      abbreviation: "XYZ"
      name: "Xevious Young Zorks"
      basePeriodCategory: "daily"
    l = new League(attributes)
    test.equal l.isNew(), true, "l.isNew()"
    l.save l.toJSON(),
      error: -> console.log "error saving new league"
      success: (model,response) ->
        test.equal model.isNew(), false
        test.ok model.id, "has id"
        test.ok model.get("_rev"), "has _rev"
        test.equal model.get("statsKey"), attributes.statsKey
        test.equal model.get("abbreviation"), attributes.abbreviation
        test.equal model.get("name"), attributes.name
        test.equal model.get("basePeriodCategory"), attributes.basePeriodCategory
        test.equal model.get("doctype"), "League"
        model.destroy
          success: -> test.done()


exports.testFetchForStatsKey = 

  setUp: (callback) ->
    @leagueStatsKey = "sadkajshdkjsahkdj"
    @league = new League
      statsKey: @leagueStatsKey
    @league.save @league.toJSON(),
      success: -> callback()

  tearDown: (callback) ->
    @league.destroy
      success: -> callback()

  testFetchForStatsKey: (test) ->
    test.ok @leagueStatsKey
    League.fetchForStatsKey @leagueStatsKey,
      error: logErrorResponse "League.fetchForStatsKey"
      success: (model,response) =>
        test.ok model
        test.equal model.id, @league.id
        test.done()


exports.testFetchOrCreateForStatsKey = (test) ->
  statsKey = "2i76qwfuyasjhcbljsa"
  League.fetchOrCreateForStatsKey statsKey,
    error: logErrorResponse "wtf"
    success: (league) ->
      test.ok league
      test.equal league.get("statsKey"),statsKey
      test.ok league.id
      League.fetchOrCreateForStatsKey statsKey,
        error: logErrorResponse "wtf"
        success: (league) ->
          test.ok league
          test.equal league.get("statsKey"),statsKey
          test.ok league.id
          league.destroy
            success: -> test.done()


