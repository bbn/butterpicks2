(function() {
  var Backbone, bbCouch, controllers, gameUpdater, http, models, port, server, static, staticFiles;

  console.log("--- butterpicks2 starting up.");

  static = require("node-static");

  staticFiles = new static.Server('./static');

  Backbone = require("backbone");

  bbCouch = require("./backbone-couch");

  Backbone.sync = bbCouch.sync;

  models = require("./models");

  controllers = require("./controllers");

  http = require("http");

  server = http.createServer(function(req, res) {
    var body;
    body = "";
    req.addListener("data", function(chunk) {
      return body += chunk;
    });
    return req.addListener("end", function() {
      return controllers.router.handle(req, body, function(result) {
        var callback, match;
        if (result.status === 404) {
          return staticFiles.serve(req, res, function(err, result) {
            if (err && err.status === 404) {
              res.writeHead(404);
              return res.end('File not found.');
            }
          });
        } else {
          if (match = req.url.match(/callback=(.*)/)) {
            callback = match[1].split("&")[0];
            result.body = "" + callback + "(" + result.body + ")";
            result.headers['Content-Length'] += callback.length + 2;
          }
          res.writeHead(result.status, result.headers);
          return res.end(result.body);
        }
      });
    });
  });

  port = process.env.PORT || 3000;

  server.listen(port);

  console.log("listening on " + port);

  gameUpdater = require("./game-updater");

  gameUpdater.poll(1000);

}).call(this);
