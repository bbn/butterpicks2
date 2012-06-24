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
            console.log "TODO - instead of deleting, flag periods and user periods as invalid"
            if response.status_code == 404
              @userPeriod.destroy
                error: options.error
                success: => options.success @
          success: (model,response) =>
            updatePoints
              error: options.error
              success: =>
                updateAchievements
                  error: options.error
                  success: =>
                    options.success @

  updatePoints: (options) ->
    console.log "FIXME update UserPeriod points based on picks made"
    options.sucess @

  updateAchievements: (options) ->
    console.log "FIXME update UserPeriod achievements based on picks made, past periods"
    options.success @
