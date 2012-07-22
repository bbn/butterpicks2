Backbone = require "backbone"

module.exports = class UserPeriod extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "UserPeriod"
    userId: null
    periodId: null
    periodStartDate: null
    periodCategory: null
    leagueId: null

    metrics: {}

  user: null
  period: null
