Job = require "./job"
_ = require "underscore"
util = require "util"
require "../../date"
Backbone = require "backbone"
couch = require "../../couch"
models = require "../../models"
Period = models.Period
Game = models.Game
User = models.User
UserPeriod = models.UserPeriod

module.exports = class UserPeriodUpdateJob extends Job

  idAttribute: "_id"

  defaults:
    job:true
    doctype: "UserPeriodUpdateJob"
    createdDate: new Date()
    userPeriodId: null
    
  work: (options) ->
    @userPeriod = new UserPeriod {id:@get("userPeriodId")}
    @userPeriod.fetch
      error: options.error
      success: (userPeriod,response) =>
        @period = new Period {id:@userPeriod.get("periodId")}
        @period.fetch
          error: (model,response) =>
            return options.error(response) unless response.status_code == 404
            console.log "CONSIDER: instead of deleting, flag periods and user periods as invalid"
            @userPeriod.destroy
              error: options.error
              success: => options.success @
          success: (model,response) =>
            @updatePoints
              error: options.error
              success: =>
                @updateAchievements
                  error: options.error
                  success: =>
                    options.success @

  updatePoints: (options) ->
    @period.fetchGames
      error: options.error
      success: (games) =>
        return options.error("zero games for period #{@period.id}") unless games.length
        @userPeriod.games = games
        @userPeriod.fetchPicks
          error: options.error
          success: (picks) =>
            points = 0
            (points += pick.points()) for pick in picks
            console.log "#{points} calculated"
            return options.success(@) if points == @userPeriod.get("points")
            @userPeriod.save {points:points},
              error: options.error
              success: (userPeriod) =>
                @userPeriod = userPeriod                
                options.success @

  updateAchievements: (options) ->
    console.log "FIXME update UserPeriod achievements based on picks made, past periods"
    options.success @
