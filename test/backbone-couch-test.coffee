###
TODO
- test if deleting a later revision of a document means the document id can no longer be fetched. 
  eg. if I delete rev 3 for doc id "xyz", is rev 2 for xyz still accessible? 
###

util = require "util"
Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync

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


exports.saveNewModel = 

  testSaveNewModel: (test) ->
    x = new TestModel()
    test.ok x, "new TestModel ok"
    test.equal x.get("a"), modelDefaults.a, "a attribute equal"
    test.equal x.get("b"), modelDefaults.b, "b attribute equal"
    test.equal x.get("c"), modelDefaults.c, "c attribute equal"
    x.save x.toJSON(), 
      error: (model,response) -> console.log "error saving x in testSaveNewModel"
      success: (model,response) ->
        test.ok model, "model returned from success ok"
        test.ok model.id, "model.id ok"
        test.ok model.get("_rev"), "model._rev ok"
        test.equal model.get("a"), modelDefaults.a, "a attribute equal"
        test.equal model.get("b"), modelDefaults.b, "b attribute equal"
        test.equal model.get("c"), modelDefaults.c, "c attribute equal"
        exports.saveNewModel.teardownModel = model
        test.done()

  tearDown: (callback) ->
    exports.saveNewModel.teardownModel.destroy
      error: (model,response) -> console.log "response: #{util.inspect response}"
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
      error: (model,response) -> console.log "response: #{util.inspect response}"
      success: (model,response) -> callback()
