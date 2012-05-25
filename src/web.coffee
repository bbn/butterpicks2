console.log "--- butterpicks2 starting up."

static = require "node-static"
staticFiles = new (static.Server)('./static')

Backbone = require "backbone"
bbCouch = require "./backbone-couch"
Backbone.sync = bbCouch.sync
models = require "./models"

controllers = require "./controllers"
    
http = require "http"

server = http.createServer (req,res) ->
  body = ""
  req.addListener "data", (chunk) ->
    body += chunk    
  req.addListener "end", ->
    controllers.router.handle req, body, (result) ->
      if result.status == 404
        staticFiles.serve req, res, (err, result) ->
          if err and err.status == 404
            res.writeHead 404
            res.end 'File not found.'
      else
        if match = req.url.match /callback=(.*)/
          callback = match[1].split("&")[0]
          result.body = "#{callback}(#{result.body})"
          result.headers['Content-Length'] += callback.length + 2
        res.writeHead result.status, result.headers
        res.end result.body   

port = process.env.PORT || 3000
server.listen port
console.log "listening on #{port}"
