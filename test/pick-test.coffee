util = require "util"
require "../lib/date"

couch = require "../lib/couch"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
Game = models.Game
User = models.User
Pick = models.Pick

logErrorResponse = (message) ->
  return (model,response) ->
    console.log "ERROR: #{message} -> response: #{util.inspect response}"

exports.modelTests = (test) ->
  game = new Game
    startDate: (new Date()).add({days:10})
  pick = new Pick()
  pick.game = game
  test.equal pick.editable(), true
  test.equal pick.final(), false
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), false
  test.equal pick.safety(), false
  test.equal pick.risk(), false
  test.equal pick.useless(), true
  test.equal pick.correctPredictionMade(), null
  test.equal pick.incorrectPredictionMade(), null
  test.equal pick.incorrectRiskMade(), null
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),1
  test.equal pick.awayValue(),1
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValues()[0],1
  test.equal pick.allValues()[1],1
  test.equal pick.allValuesNotPicked().length,2
  test.equal pick.allValuesNotPicked()[0],1
  test.equal pick.allValuesNotPicked()[1],1
  test.equal pick.valuePicked(),null
  test.equal pick.valueOfCorrectPick(),null
  test.equal pick.safetyValue(),1
  test.equal pick.bestCaseScenarioPoints(),0
  test.equal pick.worstCaseScenarioPoints(),0
  test.equal pick.points(),null
  game.set
    startDate: (new Date()).add({days:-1})
    status:
      final: true
      score:
        home: 1
        away: 7
    pickCount:
      home: 99
      away: 44
  test.equal pick.editable(), false
  test.equal pick.final(), true
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), false
  test.equal pick.safety(), false
  test.equal pick.risk(), false
  test.equal pick.useless(), true
  test.equal pick.correctPredictionMade(), false
  test.equal pick.incorrectPredictionMade(), false
  test.equal pick.incorrectRiskMade(), false
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),44
  test.equal pick.awayValue(),99
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,2
  test.equal pick.valuePicked(),null
  test.equal pick.valueOfCorrectPick(),99
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),0
  test.equal pick.worstCaseScenarioPoints(),0
  test.equal pick.points(),0
  pick.set
    away: true  
  test.equal pick.editable(), false
  test.equal pick.final(), true
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), true
  test.equal pick.safety(), false
  test.equal pick.risk(), false
  test.equal pick.useless(), false
  test.equal pick.correctPredictionMade(), true
  test.equal pick.incorrectPredictionMade(), false
  test.equal pick.incorrectRiskMade(), false
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),44
  test.equal pick.awayValue(),99
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,1
  test.equal pick.allValuesNotPicked()[0],44
  test.equal pick.valuePicked(),99
  test.equal pick.valueOfCorrectPick(),99
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),99
  test.equal pick.worstCaseScenarioPoints(),0
  test.equal pick.points(),99
  pick.set
    away: true  
    butter: true
  test.equal pick.editable(), false
  test.equal pick.final(), true
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), true
  test.equal pick.safety(), false
  test.equal pick.risk(), true
  test.equal pick.useless(), false
  test.equal pick.correctPredictionMade(), true
  test.equal pick.incorrectPredictionMade(), false
  test.equal pick.incorrectRiskMade(), false
  test.equal pick.multiplier(),2
  test.equal pick.homeValue(),88
  test.equal pick.awayValue(),198
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,1
  test.equal pick.allValuesNotPicked()[0],88
  test.equal pick.valuePicked(),198
  test.equal pick.valueOfCorrectPick(),198
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),198
  test.equal pick.worstCaseScenarioPoints(),-88
  test.equal pick.points(),198
  pick.set
    home:true
    away:false
    butter:false
  test.equal pick.editable(), false
  test.equal pick.final(), true
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), true
  test.equal pick.safety(), false
  test.equal pick.risk(), false
  test.equal pick.useless(), false
  test.equal pick.correctPredictionMade(), false
  test.equal pick.incorrectPredictionMade(), true
  test.equal pick.incorrectRiskMade(), false
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),44
  test.equal pick.awayValue(),99
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,1
  test.equal pick.allValuesNotPicked()[0],99
  test.equal pick.valuePicked(),44
  test.equal pick.valueOfCorrectPick(),99
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),44
  test.equal pick.worstCaseScenarioPoints(),0
  test.equal pick.points(),0
  pick.set
    butter:true
  test.equal pick.risk(), true
  test.equal pick.incorrectRiskMade(), true
  test.equal pick.multiplier(),2
  test.equal pick.homeValue(),88
  test.equal pick.awayValue(),198
  test.equal pick.allValuesNotPicked().length,1
  test.equal pick.allValuesNotPicked()[0],198
  test.equal pick.valuePicked(),88
  test.equal pick.valueOfCorrectPick(),198
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),88
  test.equal pick.worstCaseScenarioPoints(),-198
  test.equal pick.points(),-198
  pick.set
    butter:true
    home:false
    away:false
  test.equal pick.predictionMade(), false
  test.equal pick.safety(), true
  test.equal pick.risk(), false
  test.equal pick.useless(), false
  test.equal pick.correctPredictionMade(), false
  test.equal pick.incorrectPredictionMade(), false
  test.equal pick.incorrectRiskMade(), false
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),44
  test.equal pick.awayValue(),99
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,2
  test.equal pick.valuePicked(),null
  test.equal pick.valueOfCorrectPick(),99
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),44
  test.equal pick.worstCaseScenarioPoints(),44
  test.equal pick.points(),44
  game.set
    startDate: (new Date()).add({days:11})
    status: 
      final: false

  test.equal pick.editable(), true
  test.equal pick.final(), false
  test.equal pick.couldDraw(), false
  test.equal pick.predictionMade(), false
  test.equal pick.safety(), true
  test.equal pick.risk(), false
  test.equal pick.useless(), false
  test.equal pick.correctPredictionMade(), null
  test.equal pick.incorrectPredictionMade(), null
  test.equal pick.incorrectRiskMade(), null
  test.equal pick.multiplier(),1
  test.equal pick.homeValue(),44
  test.equal pick.awayValue(),99
  test.equal pick.drawValue(),null
  test.equal pick.allValues().length,2
  test.equal pick.allValuesNotPicked().length,2
  test.equal pick.valuePicked(),null
  test.equal pick.valueOfCorrectPick(),null
  test.equal pick.safetyValue(),44
  test.equal pick.bestCaseScenarioPoints(),44
  test.equal pick.worstCaseScenarioPoints(),44
  test.equal pick.points(),null

  test.done()


exports.pickCreateTest = (test) ->
  pickData =
    gameId: "di1b7xfbqudgw"
    userId: "dlquxknuhasjklndhalnsjh"
  Pick.create pickData,
    error: logErrorResponse "Pick.create"
    success: (pick,response) ->
      test.ok pick
      test.equal pick.id, Pick.getCouchId(pickData)

      pick.destroy
        error: logErrorResponse "pick.destroy"
        success: -> test.done()  