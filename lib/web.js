(function() {
  var controllers, http, port, server;

  console.log("STARTING UP PICKS");

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
        res.writeHead(result.status, result.headers);
        return res.end(result.body);
      });
    });
  });

  port = process.env.PORT || 3000;

  server.listen(port);

  console.log("listening on " + port);

}).call(this);
