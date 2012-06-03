Backbone = require "backbone"

module.exports = class ButterTransaction extends Backbone.Model

  defaults:
    doctype: "ButterTransaction"
    userId: null
    pickId: null
    amount: null
    createdDate: null
    note: null
