Backbone = require "backbone"

module.exports = class Pick extends Backbone.Model

  defaults:
    doctype: "Pick"
    userId: null
    gameId: null

    home: null
    away: null
    draw: null
    butter: null
    
  user: null
  game: null

  validate: (attr) ->
    total = 0
    total++ if attr.home 
    total++ if attr.away
    total++ if attr.draw
    return "can't have more than one of home,away,draw" if total > 1
    return null

  editable: ->
    return null unless @game
    return false if @game.deadlineHasPassed()
    return false if @game.postponed()
    return true

  final: -> 
    return null unless @game
    @game.get("status").final
    
  couldDraw: -> 
    return null unless @game
    @game.get("couldDraw")

  predictionMade: -> 
    return true if @.get("home") or @.get("away") or @.get("draw") 
    return false

  safety: -> 
    return true if @.get("butter") and not @predictionMade()
    return false

  risk: ->
    return true if @.get("butter") and @predictionMade()
    return false

  useless: ->
    not @predictionMade() and not @safety()

  correctPredictionMade: ->
    return null unless @final()
    return true if @game.homeWin() and @get "home"
    return true if @game.awayWin() and @get "away"
    return true if @game.draw() and @get "draw"
    return false

  incorrectPredictionMade: ->
    return null unless @final()
    return false unless @predictionMade()
    return not @correctPredictionMade()

  incorrectRiskMade: ->
    @incorrectPredictionMade() and @risk()

  correctRiskMade: ->
    @correctPredictionMade() and @risk()

  multiplier: ->
    return 2 if @risk()
    return 1

  homeValue: ->
    return null unless @game
    value = @game.get("pickCount").away
    value += @game.get("pickCount").draw if @couldDraw()
    (value or 1) * @multiplier()
  
  awayValue: ->
    return null unless @game
    value = @game.get("pickCount").home
    value += @game.get("pickCount").draw if @couldDraw()
    (value or 1) * @multiplier()

  drawValue: ->
    return null unless @game
    return null unless @couldDraw()
    value = @game.get("pickCount").home
    value += @game.get("pickCount").away
    (value or 1) * @multiplier()

  allValues: ->
    a = [@homeValue(),@awayValue()]
    a.push(@drawValue()) if @couldDraw()
    a

  allValuesNotPicked: ->
    a = []
    a.push(@homeValue()) unless @get "home"
    a.push(@awayValue()) unless @get "away"
    a.push(@drawValue()) if @couldDraw() unless @get "draw"
    a

  valuePicked: ->
    return null unless @predictionMade()
    return @homeValue() if @get "home"
    return @awayValue() if @get "away"
    return @drawValue() if @get "draw"

  valueOfCorrectPick: ->
    return null unless @final()
    return @homeValue() if @game.homeWin()
    return @awayValue() if @game.awayWin()
    return @drawValue() if @game.draw()
    return 0

  safetyValue: ->
    (Math.min.apply null,@allValues()) / @multiplier()

  bestCaseScenarioPoints: ->
    return @safetyValue() if @safety()
    return @valuePicked() if @p
    return @homeValue() if @get "home"
    return @awayValue() if @get "away"
    return @drawValue() if @get "draw"
    return 0

  worstCaseScenarioPoints: ->
    return @safetyValue() if @safety()
    return 0 unless @risk()
    return -Math.max(@allValuesNotPicked())

  points: ->
    return null unless @final()
    return @safetyValue() if @safety()
    return @valuePicked() if @correctPredictionMade()
    return -@valueOfCorrectPick() if @incorrectRiskMade()
    return 0
