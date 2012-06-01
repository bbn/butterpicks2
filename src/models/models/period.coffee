Backbone = require "backbone"

module.exports = class Period extends Backbone.Model

  defaults :
    doctype: "Period"
    league:
      abbreviation: null
      statsKey: null
    category : null
    startDate : null
    endDate : null