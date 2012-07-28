Backbone = require "backbone"

module.exports = class Period extends Backbone.Model

  idAttribute: "_id"

  defaults :
    doctype: "Period"
    leagueId: null
    category : null
    startDate : null
    endDate : null
    final : false

  games: null
  userPeriods: null

  validate: (attr) ->
    return "no leagueId attribute" unless attr.leagueId
    return "no category attribute" unless attr.category
    return "no startDate attribute" unless attr.startDate
    return "no endDate attribute" unless attr.endDate

  initialize: (attr) ->
    @set({_id:@constructor.getCouchId(attr)}) unless attr._id


  @getCouchId: (params) ->
    switch params.category
      when "daily"
        d = new Date(params.date or params.startDate)
        dateString = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
        return "#{params.leagueId}_#{params.category}_#{dateString}"
      when "lifetime"
        return "#{params.leagueId}_#{params.category}"

