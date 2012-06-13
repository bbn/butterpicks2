util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

User = models.User
Period = models.Period
UserPeriod = models.UserPeriod


logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"


exports.createUserPeriod = 
  
  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @periodData = 
          league:
            statsKey: "6rciytexutsdulblu7"
          category: "daily"
          startDate: new Date("Jan 11, 2012")
          endDate: new Date("Jan 12, 2012")
        @periodData.id = Period.getCouchId
          category: @periodData.category
          date: @periodData.startDate
          leagueStatsKey: @periodData.league.statsKey
        @period = new Period(@periodData)
        @period.save @period.toJSON(),
          error: -> logErrorResponse "saving period"
          success: -> callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @period.destroy
          error: logErrorResponse "destroying period"
          success: -> callback()

  testCreateUserPeriod: (test) ->
    test.ok @user.id
    test.ok @period.id
    params = 
      userId: @user.id
      periodId: @period.id
    UserPeriod.createForUserAndPeriod params,
      error: logErrorResponse "UserPeriod.createForUserAndPeriod"
      success: (userPeriod,response) =>
        test.ok userPeriod
        test.ok userPeriod.id
        test.equal userPeriod.get("doctype"), "UserPeriod"
        test.equal userPeriod.get("userId"), @user.id
        test.equal userPeriod.get("periodId"), @period.id
        test.equal userPeriod.get("leagueStatsKey"), @period.get("league").statsKey
        test.equal userPeriod.get("periodStartDate").toJSON(), @period.get("startDate").toJSON()
        test.equal userPeriod.get("periodCategory"), @period.get("category")
        userPeriod.destroy
          error: logErrorResponse "destroying userPeriod"
          success: -> test.done()



exports.testFetchUserPeriod = 

  setUp: (callback) ->
    @user = new User()
    @user.save @user.toJSON(),
      error: logErrorResponse "user save"
      success: (u,response) =>
        @periodData = 
          league:
            statsKey: "1iou2u4g21kg"
          category: "daily"
          startDate: new Date("Jan 11, 2012")
          endDate: new Date("Jan 12, 2012")
        @periodData.id = Period.getCouchId
          category: @periodData.category
          date: @periodData.startDate
          leagueStatsKey: @periodData.league.statsKey
        @period = new Period(@periodData)
        @period.save @period.toJSON(),
          error: -> logErrorResponse "saving period"
          success: => 
            params = 
              userId: @user.id
              periodId: @period.id
            UserPeriod.createForUserAndPeriod params,
              error: logErrorResponse "UserPeriod.createForUserAndPeriod"
              success: (userPeriod,response) =>
                @userPeriod = userPeriod
                callback()

  tearDown: (callback) ->
    @user.destroy
      error: logErrorResponse "destroying user"
      success: =>
        @period.destroy
          error: logErrorResponse "destroying period"
          success: => 
            @userPeriod.destroy
              error: logErrorResponse "destroying userPeriod"
              success: -> callback()

  testFetchUserPeriod: (test) ->
    test.ok @user.id
    test.ok @period.id
    test.ok @userPeriod.id
    params = 
      userId: @user.id
      periodId: @period.id
    UserPeriod.fetchForUserAndPeriod params,
      error: logErrorResponse "UserPeriod.fetchForUserAndPeriod"
      success: (userPeriod,response) =>
        test.ok userPeriod
        test.equal userPeriod.id, @userPeriod.id
        test.equal userPeriod.get("userId"), @user.id
        test.equal userPeriod.get("periodId"), @period.id
        test.equal userPeriod.get("leagueStatsKey"), @period.get("league").statsKey
        test.equal userPeriod.get("periodStartDate").toJSON(), @period.get("startDate").toJSON()
        test.equal userPeriod.get("periodCategory"), @period.get("category")
        test.done()
