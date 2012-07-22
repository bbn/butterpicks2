Backbone = require "backbone"
_ = require "underscore"

module.exports = class Prize extends Backbone.Model

  idAttribute: "_id"

  defaults:
    doctype: "Prize"
    leagueId: null
    name: null
    description: null
    pointValue: null

    eligibleConditions: null
    possibleConditions: null
    successConditions: null
    failConditions: null


  validate: (attr) ->
    return "no leagueId" unless attr.leagueId
    return "no conditions" unless attr.eligibleConditions or attr.possibleConditions or attr.successConditions or attr.failConditions
    conditions = _.flatten attr.eligibleConditions,attr.possibleConditions,attr.successConditions,attr.failConditions
    validOperators = [">",">=","==","<","<="]
    for condition in conditions
      return "no metric for condition #{condition}" unless condition.metric
      return "no operator for condition #{condition}" unless condition.operator
      return "no value for condition #{condition}" if (condition.value==undefined)
      return "invalid operator for condition #{condition}" if (_(validOperators).indexOf(condition.operator)==-1)
    return "no pointValue" if attr.pointValue==null
    return "no name" unless attr.name


  satisfies: (metrics,conditions) ->
    return true unless conditions
    return false unless metrics
    for condition in conditions
      return false if (metrics[condition.metric] == undefined)
      switch condition.operator
        when '>'
          return false unless metrics[condition.metric] > condition.value
        when '>='
          return false unless metrics[condition.metric] >= condition.value
        when '=='
          return false unless metrics[condition.metric] == condition.value
        when '<'
          return false unless metrics[condition.metric] < condition.value
        when '<='
          return false unless metrics[condition.metric] <= condition.value
    return true


  eligible: (metrics) -> @satisfies metrics, @get("eligibleConditions")

  possible: (metrics) -> @eligible(metrics) and (not @fail(metrics)) and (@satisfies metrics, @get("possibleConditions"))

  success:  (metrics) -> @possible(metrics) and @satisfies metrics, @get("successConditions")

  fail:     (metrics) -> @satisfies metrics, @get("failConditions")