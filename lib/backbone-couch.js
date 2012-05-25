(function() {
  var couchUrl, db, dbName, documentUpdateConflictError, util, _;

  _ = require("underscore");

  util = require("util");

  couchUrl = process.env.CLOUDANT_URL || "http://localhost:5984";

  dbName = process.env.CLOUDANT_DB || process.env.testingDbName || 'picks';

  db = require("nano")(couchUrl).use(dbName);

  console.log("bbCouch: using '%s' database", dbName);

  documentUpdateConflictError = function() {
    var err;
    err = new Error("Document update conflict.");
    err.reason = "Document update conflict.";
    err.statusCode = 409;
    return err;
  };

  exports.sync = function(method, model, options) {
    var error, success;
    success = options.success;
    error = options.error;
    switch (method) {
      case "read":
        if (!model.id) error(new Error("no id"));
        return db.get(model.id, function(err, body, header) {
          if (err) return error(err);
          return success(body);
        });
      case "update":
      case "create":
        if (model.get("_rev")) {
          return db.get(model.id, function(err, body, header) {
            var newDoc;
            if (err) return error(err);
            if (body._rev !== model.get("_rev")) {
              return error(documentUpdateConflictError());
            }
            newDoc = _(body).extend(model.toJSON());
            return db.insert(newDoc, newDoc.id, function(err, body, header) {
              if (err) return error(err);
              return success({
                _rev: body.rev,
                _id: body.id,
                id: body.id
              });
            });
          });
        } else {
          return db.insert(model.toJSON(), function(err, body, header) {
            if (err) return error(err);
            return success({
              _rev: body.rev,
              _id: body.id,
              id: body.id
            });
          });
        }
        break;
      case "delete":
        return db.get(model.id, function(err, body, header) {
          if (err) return error(err);
          if (body._rev !== model.get("_rev")) {
            return error(documentUpdateConflictError());
          }
          return db.destroy(model.id, model.get("_rev"), function(err, body, header) {
            if (err) return error(err);
            return success(body);
          });
        });
    }
  };

}).call(this);
