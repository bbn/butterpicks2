Backbone = require "backbone"

module.exports = class UserPeriod extends Backbone.Model

  defaults:
    doctype: "UserPeriod"
    userId: null
    periodId: null
    periodStartDate: null
    periodCategory: null
    leagueStatsKey: null
    
    points: 0
    prizes: null

  user: null
  period: null
