Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync

logErrorResponse = (model,response) ->
  console.log "response: #{require('util').inspect response}"

modelDefaults =
  a: 1
  b: 2
  c: "see"

class TestModel extends Backbone.Model
  defaults: modelDefaults
  url: =>
    return @get "_id"


exports.testURL = (test) ->
  x = new TestModel( { _id:"blerg" } )
  test.ok x.url
  test.equal typeof(x.url),"function"
  test.equal x.url(), "blerg"
  test.done()


exports.createModel = 

  testCreateModel: (test) ->
    x = new TestModel()
    test.ok x, "new TestModel ok"
    test.equal x.get("a"), modelDefaults.a, "a attribute equal"
    test.equal x.get("b"), modelDefaults.b, "b attribute equal"
    test.equal x.get("c"), modelDefaults.c, "c attribute equal"
    x.save x.toJSON(), 
      error: (model,response) -> console.log "error saving x in testCreateModel"
      success: (model,response) ->
        test.ok model, "model returned from success ok"
        test.ok model.id, "model.id ok"
        test.ok model.get("_rev"), "model._rev ok"
        test.equal model.get("a"), modelDefaults.a, "a attribute equal"
        test.equal model.get("b"), modelDefaults.b, "b attribute equal"
        test.equal model.get("c"), modelDefaults.c, "c attribute equal"
        exports.createModel.teardownModel = model
        test.done()

  tearDown: (callback) ->
    exports.createModel.teardownModel.destroy
      error: logErrorResponse
      success: (model,response) -> callback()


exports.readModel = 

  setUp: (callback) ->
    x = new TestModel()
    x.save x.toJSON(),
      error: (model,response) -> console.log "error saving x in updateModel"
      success: (model,response) ->
        exports.readModel.id = x.id
        exports.readModel.model = x
        callback()

  testReadModel: (test) ->
    id = exports.readModel.id
    x = new TestModel({ id: id })
    x.fetch
      error: (model,response) -> console.log "error fetching x in readModel"
      success: (model,response) ->
        test.ok model, "model ok"
        test.ok model.id, "model.id ok"
        test.ok model.get("_rev"), "model._rev ok"
        test.equal model.get("a"), modelDefaults.a, "a attribute equal"
        test.equal model.get("b"), modelDefaults.b, "b attribute equal"
        test.equal model.get("c"), modelDefaults.c, "c attribute equal"
        test.done()

  tearDown: (callback) ->
    exports.readModel.model.destroy
      error: logErrorResponse
      success: (model,response) -> callback()


exports.updateModel = 

  setUp: (callback) ->
    x = new TestModel()
    x.save x.toJSON(),
      error: (model,response) -> console.log "error saving x in updateModel"
      success: (model,response) ->
        exports.updateModel.model = x
        callback()

  testUpdateModel: (test) ->
    model = exports.updateModel.model
    test.ok model.id, "model.id ok"
    test.ok model.get("_rev"), "model _rev ok"
    test.equal model.get("a"), modelDefaults.a, "a attribute equal"
    test.equal model.get("b"), modelDefaults.b, "b attribute equal"
    test.equal model.get("c"), modelDefaults.c, "c attribute equal"
    newVals = 
      a: 11
      b: 22
      c: 33
      d: "egghead"
    model.save newVals,
      error: (model,response) -> console.log "error updating model in updateModel"
      success: (model,response) ->
        test.ok model, "model returned from success ok"
        test.ok model.id, "model.id ok"
        test.ok model.get("_rev"), "model._rev ok"
        test.equal model.get("a"), newVals.a, "a attribute updated"
        test.equal model.get("b"), newVals.b, "b attribute updated"
        test.equal model.get("c"), newVals.c, "c attribute updated"
        test.equal model.get("d"), newVals.d, "d attribute updated"
        exports.updateModel.model = model
        test.done()

  tearDown: (callback) ->
    exports.updateModel.model.destroy
      error: logErrorResponse
      success: (model,response) -> callback()


exports.destroyModel = 

  setUp: (callback) ->
    x = new TestModel()
    x.save x.toJSON(),
      error: (model,response) -> console.log "error saving x in updateModel"
      success: (model,response) ->
        exports.destroyModel.model = x
        callback()

  testDestroyModel: (test) ->
    exports.destroyModel.model.destroy
      error: logErrorResponse
      success: (model,response) -> 
        model.fetch 
          success: logErrorResponse
          error: (model,response) -> 
            test.equal response.status_code, 404, "expect 404"
            test.equal response.error, 'not_found', "expect not_found"
            test.done()


exports.testMultipleRevisionDestroy = 

  setUp: (callback) ->
    x = new TestModel()
    x.save x.toJSON(),
      error: (model,response) -> console.log "error saving x in updateModel"
      success: (model,response) ->
        x.save {blerglepuss:707},
          error: (model,response) -> console.log "error on 2nd save for x in updateModel"
          success: (model,response) ->
            exports.testMultipleRevisionDestroy.model = x
            callback()

  testMultipleRevisionDestroy: (test) ->
    model = exports.testMultipleRevisionDestroy.model
    test.ok model, "model ok"
    test.ok model.get("_rev"), "_rev is ok"
    test.equal model.get("_rev")[0], '2', "revision is #2"
    model.destroy
      error: logErrorResponse
      success: (model,response) ->
        test.ok model, "model is ok after deleting"
        test.ok model.id, "model still has id after deleting"
        newModel = new TestModel({ id: model.id })
        newModel.fetch
          success: logErrorResponse
          error: (model,response) -> 
            test.equal response.status_code, 404, "expect 404"
            test.equal response.error, 'not_found', "expect not_found"
            test.done()


exports.testFetchingDate = 

  setUp: (callback) ->
    exports.testFetchingDate.date = new Date()
    x = new TestModel({someDate: exports.testFetchingDate.date})
    x.save x.toJSON(),
      error: logErrorResponse
      success: (model,response) -> 
        exports.testFetchingDate.modelId = model.id        
        exports.testFetchingDate.model = model
        callback()

  testDates: (test) ->
    id = exports.testFetchingDate.modelId
    x = new TestModel({ id:id })
    x.fetch
      error: logErrorResponse
      success: (model,response) ->
        test.ok model, "model is ok"
        d = model.get("someDate")
        test.equal Object.prototype.toString.call(d), "[object Date]", "properly typed"
        test.equal JSON.stringify(d), JSON.stringify(exports.testFetchingDate.date), "same dates"
        test.done()

  tearDown: (callback) -> 
    exports.testFetchingDate.model.destroy
      error: logErrorResponse
      success: -> callback()


exports.testNestedJson = (test) ->
  x = new TestModel()
  x.set
    nest:
      x: 99
      y: 88
      z: "goof"
  x.save x.toJSON(),
    error: logErrorResponse
    success: (model,response) ->
      test.ok model, "model is ok"
      nest = model.get "nest"
      test.equal nest.x,99
      test.equal nest.y,88
      test.equal nest.z,"goof"
      test.ok model.id
      y = new TestModel({ id: model.id })
      y.fetch
        error: logErrorResponse
        success: (model,response) ->
          test.ok model, "model is ok"
          nest = model.get "nest"
          test.equal nest.x,99
          test.equal nest.y,88
          test.equal nest.z,"goof"          
          #cleanup
          model.destroy
            error: logErrorResponse
            success: -> test.done()
