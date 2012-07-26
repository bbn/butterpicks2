Backbone = require "backbone"

module.exports = class League extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "League"
    statsKey: null
    imageUrl: null
    abbreviation: null
    name: null
    draws: false
    basePeriodCategory: "daily"
    