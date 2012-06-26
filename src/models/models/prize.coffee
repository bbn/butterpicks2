Backbone = require "backbone"

module.exports = class Prize extends Backbone.Model

  defaults :
    doctype: "Prize"
    name: null
    pointValue: null
    rule: "function (results) { return false; }"
    prerequisities: []


  validate: (attr) ->
    return "no rule attribute" unless attr.rule
    return "no pointValue" if attr.pointValue==null
    return "no name" unless attr.name
    