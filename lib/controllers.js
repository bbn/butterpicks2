(function() {
  var controllers, couch, journey;

  couch = require("./couch");

  journey = require("journey");

  controllers = exports;

  controllers.router = new journey.Router;

  controllers.router.map(function() {
    this.root.bind(function(req, res) {
      return res.send("welcome");
    });
    return this.post("/from-gae/couchmodel-put").bind(function(req, res, params) {
      if (!params.gaekey) {
        console.log("no gaekey");
        return res.send(403, {}, {
          error: "no gaekey"
        });
      }
      if (!params.doctype) {
        return res.send(403, {}, {
          error: "no doctype"
        });
      }
      console.log("/from-gae/couchmodel-put: " + params.doctype);
      res.send(202, {}, params);
      return couch.db.view("gaedocs/allByKey", {
        key: params.gaekey,
        include_docs: true
      }, function(err, data) {
        if (data && data.length > 0) {
          params._rev = data[0].doc._rev;
          params._id = data[0].doc._id;
        }
        return couch.db.save(params, function(err, response) {
          if (err) {
            return console.log("error saving");
          } else {
            return console.log("successfully saved");
          }
        });
      });
    });
  });

}).call(this);
