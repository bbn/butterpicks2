console.log "STARTING UP PICKS!"

controllers = require "./controllers"
    
http = require "http"
server = http.createServer (req,res) ->
  body = ""
  req.addListener "data", (chunk) ->
    body += chunk    
  req.addListener "end", ->
    controllers.router.handle req, body, (result) ->
      res.writeHead result.status, result.headers
      res.end result.body

port = process.env.PORT || 3000
server.listen port
console.log "listening on #{port}"

