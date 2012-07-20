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
      success: (userPeriod) =>
        @userPeriod.fetchPeriod
          error: (__,response) =>
            return options.error(response) unless response.status_code == 404
            @userPeriod.destroy
              error: options.error
              success: => options.success @
          success: (period) =>
            @period = period
            @updatePoints
              error: options.error
              success: =>
                return options.success(@) unless @period.get("final")
                @updatePrizes
                  error: options.error
                  success: =>
                    options.success @

  updatePoints: (options) ->
    @userPeriod.fetchGames
      error: options.error
      success: (games) =>
        return options.error("zero games for period #{@period.id}") unless games.length
        @userPeriod.games = games
        @userPeriod.fetchPicks
          error: options.error
          success: (picks) =>
            points = 0
            (points += pick.points()) for pick in picks
            metrics = @userPeriod.get("metrics")
            return options.success(@) if metrics.points == points
            metrics.points = points
            @userPeriod.save {metrics:metrics},
              error: options.error
              success: (userPeriod) =>
                options.success @

  updatePrizes: (options) ->
    @userPeriod.determinePrizes
      error: options.error
      success: (prizes) =>
        metrics = @userPeriod.get("metrics")
        for prize in prizes
          if prize.won
            metrics[prize.id] = 1
          else
            delete metrics[prize.id]
        @userPeriod.save {metrics:metrics},
          error: options.error
          success: (userPeriod) =>
            options.success @
