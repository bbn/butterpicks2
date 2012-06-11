Backbone = require "backbone"

module.exports = class UserPeriod extends Backbone.Model
  
  defaults:
    user: null
    period: null # league: null,
    picks: null

    points: null
    prizes: null
