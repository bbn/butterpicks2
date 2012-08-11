couch = require "../../couch"
require "util"
Backbone = require "backbone"

module.exports = class Job extends Backbone.Model

  idAttribute: "_id"

  defaults:
    job: true
    doctype: "Job"
    createdDate: new Date()

  initialize: ->
    @.set({job:true}) unless @get("job")
    @.set({createdDate:new Date()}) unless @get("createdDate")
    console.log "ERROR: need a doctype in defaults!" unless @get("doctype")

  work: (options) ->
    console.log "FIXME override work method in #{@get('doctype')}"
    options.error @


  @workSuspended: false

  @create: (params,options) ->
    j = new @
    j.save params,
      error: options.error
      success: (job,response) =>
        options.success job,response
        @startWorking() unless @workSuspended


  @workInProgress: false

  @startWorking: ->
    @doWork() unless @workInProgress

    
  @doWork: ->
    @workInProgress = true
    @getNext
      error: (model,response) => 
        console.log "!!! fetching next job error: #{util.inspect response}"
        @doWork()
      success: (model,response) =>
        return @stopWorking() unless model
        model.work
          error: (_,response) => 
            console.log "!!! work error: #{util.inspect response}"
            @doWork()
          success: (model) =>
            model.destroy
              error: => 
                console.log "!!! deleting job error: #{util.inspect response}"
                @doWork()
              success: => @doWork() unless @workSuspended

  @stopWorking: ->
    console.log "@stopWorking"
    @workInProgress = false

  @getNext: (options) ->
    doctype = @.prototype.defaults.doctype
    viewParams =
      startkey: [doctype,'1970-01-01T00:00:00.000Z']
      endKey: [doctype,'2070-01-01T00:00:00.000Z']
      include_docs: true
      limit: options.limit or 1
    couch.db.view "jobs","byType", viewParams, (err,body,headers) =>
      return options.error(null,err) if err
      jobs = (new @(row.doc) for row in body.rows)
      jobs = jobs[0] if viewParams.limit == 1
      options.success jobs, headers
