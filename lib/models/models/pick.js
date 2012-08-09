(function() {
  var Backbone, Pick,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = Pick = (function(_super) {

    __extends(Pick, _super);

    function Pick() {
      Pick.__super__.constructor.apply(this, arguments);
    }

    Pick.prototype.idAttribute = "_id";

    Pick.prototype.defaults = {
      doctype: "Pick",
      userId: null,
      gameId: null,
      home: null,
      away: null,
      draw: null,
      butter: null,
      createdDate: null,
      updatedDate: null
    };

    Pick.prototype.user = null;

    Pick.prototype.game = null;

    Pick.prototype.validate = function(attr) {
      var total;
      total = 0;
      if (attr.home) total++;
      if (attr.away) total++;
      if (attr.draw) total++;
      if (total > 1) return "can't have more than one of home,away,draw";
      return null;
    };

    Pick.prototype.editable = function() {
      if (!this.game) return null;
      if (this.game.deadlineHasPassed()) return false;
      if (this.game.postponed()) return false;
      return true;
    };

    Pick.prototype.final = function() {
      if (!this.game) return null;
      return this.game.final();
    };

    Pick.prototype.couldDraw = function() {
      if (!this.game) return null;
      return this.game.get("couldDraw");
    };

    Pick.prototype.prediction = function() {
      if (!(this.get("home") || this.get("away") || this.get("draw"))) {
        return false;
      }
      return true;
    };

    Pick.prototype.safety = function() {
      if (this.get("butter") && !this.prediction()) return true;
      return false;
    };

    Pick.prototype.risk = function() {
      if (this.get("butter") && this.prediction()) return true;
      return false;
    };

    Pick.prototype.useless = function() {
      return !this.prediction() && !this.safety();
    };

    Pick.prototype.correctPrediction = function() {
      if (!this.final()) return null;
      if (this.game.homeWin() && this.get("home")) return true;
      if (this.game.awayWin() && this.get("away")) return true;
      if (this.game.draw() && this.get("draw")) return true;
      return false;
    };

    Pick.prototype.incorrectPrediction = function() {
      if (!this.final()) return null;
      if (!this.prediction()) return false;
      return !this.correctPrediction();
    };

    Pick.prototype.incorrectRisk = function() {
      return this.incorrectPrediction() && this.risk();
    };

    Pick.prototype.correctRisk = function() {
      return this.correctPrediction() && this.risk();
    };

    Pick.prototype.multiplier = function() {
      if (this.risk()) return 2;
      return 1;
    };

    Pick.prototype.homeValue = function() {
      var value;
      if (!this.game) return null;
      value = this.game.get("pickCount").away;
      if (this.couldDraw()) value += this.game.get("pickCount").draw;
      return (value || 1) * this.multiplier();
    };

    Pick.prototype.awayValue = function() {
      var value;
      if (!this.game) return null;
      value = this.game.get("pickCount").home;
      if (this.couldDraw()) value += this.game.get("pickCount").draw;
      return (value || 1) * this.multiplier();
    };

    Pick.prototype.drawValue = function() {
      var value;
      if (!this.game) return null;
      if (!this.couldDraw()) return null;
      value = this.game.get("pickCount").home;
      value += this.game.get("pickCount").away;
      return (value || 1) * this.multiplier();
    };

    Pick.prototype.allValues = function() {
      var a;
      a = [this.homeValue(), this.awayValue()];
      if (this.couldDraw()) a.push(this.drawValue());
      return a;
    };

    Pick.prototype.allValuesNotPicked = function() {
      var a;
      a = [];
      if (!this.get("home")) a.push(this.homeValue());
      if (!this.get("away")) a.push(this.awayValue());
      if (this.couldDraw()) if (!this.get("draw")) a.push(this.drawValue());
      return a;
    };

    Pick.prototype.valuePicked = function() {
      if (!this.prediction()) return null;
      if (this.get("home")) return this.homeValue();
      if (this.get("away")) return this.awayValue();
      if (this.get("draw")) return this.drawValue();
    };

    Pick.prototype.valueOfCorrectPick = function() {
      if (!this.final()) return null;
      if (this.game.homeWin()) return this.homeValue();
      if (this.game.awayWin()) return this.awayValue();
      if (this.game.draw()) return this.drawValue();
      return 0;
    };

    Pick.prototype.safetyValue = function() {
      return (Math.min.apply(null, this.allValues())) / this.multiplier();
    };

    Pick.prototype.bestCaseScenarioPoints = function() {
      if (this.safety()) return this.safetyValue();
      if (this.p) return this.valuePicked();
      if (this.get("home")) return this.homeValue();
      if (this.get("away")) return this.awayValue();
      if (this.get("draw")) return this.drawValue();
      return 0;
    };

    Pick.prototype.worstCaseScenarioPoints = function() {
      if (this.safety()) return this.safetyValue();
      if (!this.risk()) return 0;
      return -Math.max(this.allValuesNotPicked());
    };

    Pick.prototype.points = function() {
      if (!this.final()) return null;
      if (this.safety()) return this.safetyValue();
      if (this.correctPrediction()) return this.valuePicked();
      if (this.incorrectRisk()) return -this.valueOfCorrectPick();
      return 0;
    };

    return Pick;

  })(Backbone.Model);

}).call(this);
