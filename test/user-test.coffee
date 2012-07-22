util = require "util"
_ = require "underscore"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
require "../lib/model-server-utils"


User = models.User
League = models.League
Period = models.Period
UserPeriod = models.UserPeriod

console.log "TODO test createdAt default. loading existing model does not replace with default?"

logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createUser = 

  testCreateUser: (test) ->
    newUserAttributes =
      facebookId: 751395611
      email: "ben@mainsocial.com" 
    u = new User(newUserAttributes)
    test.equal u.isNew(), true, "u.isNew()"
    u.save u.toJSON(),
      error: (model,response) ->
        console.log "error saving new user in exports.save"
      success: (model,response) ->
        test.equal model.isNew(), false
        test.ok model.id, "has id"
        test.ok model.get("_rev"), "has _rev"
        test.equal model.get("facebookId"), newUserAttributes.facebookId
        test.equal model.get("email"), newUserAttributes.email
        test.equal model.get("doctype"), "User"
        exports.createUser.teardownModel = model
        test.done()

  tearDown: (callback) ->
    exports.createUser.teardownModel.destroy
      error: (model,response) -> console.log "error destroying model in exports.save"
      success: (model,response) -> callback()


exports.testFetchUser = 

  setUp: (callback) ->
    @userAttributes = 
      facebookId: 751395611
      email: "ben@mainsocial.com" 
    u = new User(@userAttributes)
    u.save u.toJSON(),
      error: (model,response) -> console.log "error saving new user"
      success: (model,response) =>
        @userId = model.id
        callback()

  testFetchUser: (test) ->
    id = @userId
    test.ok id, "should have passed an id via this keyword"
    u = new User({ id:id })
    u.fetch
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) =>
        test.ok model
        test.equal model.id, id, "same id"
        test.equal model.get("facebookId"),@userAttributes.facebookId,"same facebookId"
        test.equal model.get("email"),@userAttributes.email,"same email"
        test.equal model.get("doctype"),"User"
        test.done()

  tearDown: (callback) ->
    id = @userId
    u = new User({ id:id })
    u.fetch
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) ->
        model.destroy
          error: (model,response) -> console.log "response: #{util.inspect response}"
          success: -> callback()


exports.testUserFetchMetrics = (test) ->
  user = new User
  user.save user.toJSON(),
    error: logErrorResponse "user.save"
    success: (user) ->
      league = new League
      league.save league.toJSON(),
        error: logErrorResponse "league.save"
        success: (league) ->
          period1 = new Period
            leagueId: league.id
            category: "daily"
            startDate: new Date(2011,1,2)
            endDate: new Date(2011,1,3)
            final: true
          period1.save period1.toJSON(),
            error: logErrorResponse "period1.save"
            success: (period1) ->
              period2 = new Period
                leagueId: league.id
                category: "daily"
                startDate: new Date(2011,1,3)
                endDate: new Date(2011,1,4)
                final: true
              period2.save period2.toJSON(),
                error: logErrorResponse "period2.save"
                success: (period2) ->
                  userPeriod1 = new UserPeriod
                    userId: user.id
                    periodId: period1.id
                    periodStartDate: period1.get("startDate")
                    periodCategory: period1.get("category")
                    leagueId: league.id
                    metrics:
                      points: 10
                      stars: 1
                      risks: 4
                  userPeriod1.save userPeriod1.toJSON(),
                    error: logErrorResponse "userPeriod1.save"
                    success: (userPeriod1) ->
                      userPeriod2 = new UserPeriod
                        userId: user.id
                        periodId: period2.id
                        periodStartDate: period2.get("startDate")
                        periodCategory: period2.get("category")
                        leagueId: league.id
                        metrics:
                          points: 100
                          stars: 10
                          ribbons: 1
                      userPeriod2.save userPeriod2.toJSON(),
                        error: logErrorResponse "userPeriod2.save"
                        success: (userPeriod2) ->
                          user.fetchMetrics
                            leagueId: league.id
                            endDate: (new Date(2011,1,1))
                            error: logErrorResponse "user.fetchMetrics 1"
                            success: (metrics) ->
                              test.equal _(metrics).keys().length, 0
                              user.fetchMetrics
                                leagueId: league.id
                                endDate: (new Date(2011,1,2))
                                error: logErrorResponse "user.fetchMetrics 2"
                                success: (metrics) ->
                                  test.equal metrics.points, 10
                                  test.equal metrics.stars, 1
                                  test.equal metrics.risks, 4
                                  user.fetchMetrics
                                    leagueId: league.id
                                    endDate: (new Date(2011,1,6))
                                    error: logErrorResponse "user.fetchMetrics 3"
                                    success: (metrics) ->
                                      test.equal metrics.points, 110
                                      test.equal metrics.stars, 11
                                      test.equal metrics.risks, 4
                                      test.equal metrics.ribbons, 1
                                      user.fetchMetrics
                                        leagueId: league.id
                                        startDate: (new Date(2011,1,3))
                                        error: logErrorResponse "user.fetchMetrics 4"
                                        success: (metrics) ->
                                          test.equal metrics.points, 100
                                          test.equal metrics.stars, 10
                                          test.equal metrics.ribbons, 1                                      
                                          user.fetchMetrics
                                            leagueId: league.id
                                            startDate: (new Date(2011,1,6))
                                            error: logErrorResponse "user.fetchMetrics 5"
                                            success: (metrics) ->
                                              test.equal _(metrics).keys().length,0
                                              userPeriod1.destroy
                                                success: ->
                                                  userPeriod2.destroy
                                                    success: ->
                                                      period2.destroy
                                                        success: ->
                                                          period1.destroy
                                                            success: ->
                                                              league.destroy
                                                                success: ->
                                                                  user.destroy
                                                                    success: ->
                                                                      test.done()



