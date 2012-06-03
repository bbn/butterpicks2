_ = require "underscore"
Backbone = require "backbone"
couch = require "../../couch"

module.exports = class PeriodUpdateJob extends Backbone.Model

  @doctype: "PeriodUpdateJob"

  idAttribute: "_id"

  defaults:
    job: true
    doctype: "PeriodUpdateJob" #FIXME how to refer to the class variable?
    createdDate: new Date()
    periodId: null
    league:
      statsKey: null
      abbreviation: null
    category: null
    withinDate: null

  @create: (params,options) ->
    j = new @
    j.save params,
      error: options.error
      success: (job,response) =>
        process.nextTick @startWorker
        options.success job,response

  @startWorker: ->
    console.log "TODO @startWorker"

  @getNext: (options) ->
    viewParams =
      startkey: [@doctype,'1970-01-01T00:00:00.000Z']
      endKey: [@doctype,'2070-01-01T00:00:00.000Z']
      include_docs: true
      limit: options.limit or 1
    couch.db.view "jobs","byType", viewParams, (err,body,headers) =>
      return options.error(null,err) if err
      jobs = new @(row.doc) for row in body.rows
      jobs = [jobs] if options.limit and not _(jobs).isArray()
      options.success jobs, headers
