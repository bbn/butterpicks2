util = require "util"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"

User = models.User
League = models.League
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
        @leagueStatsKey = "6rciytexutsdulblu7"
        @league = new League
          statsKey: @leagueStatsKey
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: (league,response) =>
            @periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Jan 11, 2012")
              endDate: new Date("Jan 12, 2012")
            @periodData.id = Period.getCouchId
              category: @league.get("basePeriodCategory")
              date: @periodData.startDate
              leagueStatsKey: @league.get("statsKey")
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
          success: => 
            @league.destroy
              error: logErrorResponse "@league.destroy"
              success: =>
                callback()

  testCreateUserPeriod: (test) ->
    test.ok @user.id
    test.ok @period.id
    test.ok @league.id
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
        test.equal userPeriod.get("leagueId"), @league.id
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
        @league = new League
          statsKey: @leagueStatsKey
          basePeriodCategory: "daily"
        @league.save @league.toJSON(),
          error: logErrorResponse "@league.save"
          success: (league,response) =>
            @periodData = 
              leagueId: @league.id
              category: @league.get "basePeriodCategory"
              startDate: new Date("Jan 11, 2012")
              endDate: new Date("Jan 12, 2012")
            @periodData.id = Period.getCouchId
              category: @league.get("basePeriodCategory")
              date: @periodData.startDate
              leagueStatsKey: @league.get("statsKey")
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
              success: => 
                @league.destroy
                  error: logErrorResponse "@league.destroy"
                  success: => callback()

  testFetchUserPeriod: (test) ->
    test.ok @user.id
    test.ok @league.id
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
        test.equal userPeriod.get("leagueId"), @period.get("leagueId")
        test.equal userPeriod.get("periodStartDate").toJSON(), @period.get("startDate").toJSON()
        test.equal userPeriod.get("periodCategory"), @period.get("category")
        test.done()
