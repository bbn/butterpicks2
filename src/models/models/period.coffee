Backbone = require "backbone"

module.exports = class Period extends Backbone.Model

  defaults :
    doctype: "Period"
    league:
      statsKey: null
    category : null
    startDate : null
    endDate : null

    name: null
    userCount : null

    games : null

