Backbone = require "backbone"

module.exports = class ButterTransaction extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "ButterTransaction"
    userId: null
    pickId: null
    amount: null
    createdDate: null
    note: null
