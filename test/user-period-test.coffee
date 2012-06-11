util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

User = models.User
Period = models.Period
UserPeriod = models.UserPeriod


exports.createUserPeriod = 

  testCreateUserPeriod: (test) ->
    test.ok false, "implement testCreateUserPeriod. using a factory?"
    test.done()



exports.testFetchUserPeriod = 

  setUp: (callback) ->
    callback()

  testFetchUserPeriod: (test) ->
    test.ok false, "implement testFetchUserPeriod"
    test.done()

  tearDown: (callback) ->
    callback()
