(function() {
  var Backbone, ButterTransaction,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Backbone = require("backbone");

  module.exports = ButterTransaction = (function(_super) {

    __extends(ButterTransaction, _super);

    function ButterTransaction() {
      ButterTransaction.__super__.constructor.apply(this, arguments);
    }

    ButterTransaction.prototype.idAttribute = "_id";

    ButterTransaction.prototype.defaults = {
      doctype: "ButterTransaction",
      userId: null,
      pickId: null,
      amount: null,
      createdDate: null,
      note: null
    };

    return ButterTransaction;

  })(Backbone.Model);

}).call(this);
