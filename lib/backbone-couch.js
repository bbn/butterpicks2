(function() {
  var couchUrl, db, dbName, documentUpdateConflictError, nano, tranformAttributesFromFetching, transformAttributesForSaving, util, _,
    __hasProp = Object.prototype.hasOwnProperty;

  _ = require("underscore");

  util = require("util");

  couchUrl = process.env.CLOUDANT_URL || "http://localhost:5984";

  dbName = process.env.CLOUDANT_DB || process.env.testingDbName || 'picks';

  nano = require("nano")(couchUrl);

  db = nano.use(dbName);

  console.log("bbCouch: using '%s' database", dbName);

  documentUpdateConflictError = function() {
    var err;
    err = new Error("Document update conflict.");
    err.reason = "Document update conflict.";
    err.statusCode = 409;
    return err;
  };

  transformAttributesForSaving = function(attributes) {
    var key, val;
    for (key in attributes) {
      if (!__hasProp.call(attributes, key)) continue;
      val = attributes[key];
      if (key.match(/Date$/)) attributes[key] = JSON.stringify(val);
    }
    return attributes;
  };

  tranformAttributesFromFetching = function(attributes) {
    var key, val;
    for (key in attributes) {
      if (!__hasProp.call(attributes, key)) continue;
      val = attributes[key];
      if (key.match(/Date$/)) attributes[key] = new Date(JSON.parse(val));
    }
    return attributes;
  };

  exports.sync = function(method, model, options) {
    var attributes, error, id, success;
    success = options.success;
    error = options.error;
    switch (method) {
      case "read":
        id = model.id || model.get("id");
        if (!id) error(new Error("no id"));
        return db.get(id, function(err, body, header) {
          if (err) return error(err);
          return success(tranformAttributesFromFetching(body));
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
            body = tranformAttributesFromFetching(body);
            newDoc = _(body).extend(model.toJSON());
            newDoc = transformAttributesForSaving(newDoc);
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
          attributes = transformAttributesForSaving(model.toJSON());
          return db.insert(attributes, function(err, body, header) {
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
