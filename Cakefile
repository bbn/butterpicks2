fs = require 'fs'
util = require 'util'

{print} = require 'util'
{spawn} = require 'child_process'

sources = 
  "lib":"src"
  "lib/models":"src/models"
  "static/js":"static/coffee"

compile = (lib,src,callback) ->
  coffee = spawn 'coffee', ['-c', '-o', lib, src]
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?(lib,src) if code is 0

browserify = (callback) ->
  x = spawn 'browserify', ['src/models/models.coffee','-o','static/js/models.js']
  x.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  x.stdout.on 'data', (data) ->
    print data.toString()
  x.on 'exit', (code) ->
    if code is 0
      print "browserified!\n"
    callback(code)
    
option '-t', '--test', 'run tests after building'
    
task 'build', 'Build lib/ from src/', (options) ->
  sourceCount = 0
  for lib,src of sources
    sourceCount += 1
  for lib,src of sources
    compile lib,src, (lib,src) ->
      print "compiled #{src} -> #{lib}\n"
      sourceCount -= 1
      if sourceCount == 0
        print "compiled successfully.\n"
        print "browserifying...\n"
        browserify (resultCode) ->
          if resultCode != 0
            print "ERROR BROWSERIFYING"
            return
          if options.test
            invoke 'test'
    
    
task 'test', 'Run all tests', ->
  process.env.testing = true
  tests = spawn "./node_modules/nodeunit/bin/nodeunit", ['test']
  tests.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  tests.stdout.on 'data', (data) ->
    print data
  tests.on 'exit', (code) ->
    print "Tests finished.\n"    
  


# compare and optionally update design documents

option '-p', '--production', 'use production couchdb'
option '-t', '--testing', 'use testing couchdb'
option '-u', '--update', 'update design documents (careful!)'

task 'couchdesign', 'check the design of the couchdb document', (options) ->
  if options.testing
    process.env.testing = true
  else if options.production
    process.env.CLOUDANT_URL = "https://app1777531.heroku:885tk871iqj5ooraJQC4L5gS@app1777531.heroku.cloudant.com"
  couch = require "./lib/couch" 
  couch.identifyUnmatchedDesignDocs (err,unmatched) ->
    if err
      print util.inspect err
    else
      if unmatched.length == 0
        print "no unmatched design documents.\n"
      else
        print "\nunmatched design documents:\n\n"
        for nonmatch in unmatched
          print nonmatch.name,"\n"
          print " new: ",util.inspect(nonmatch.design),"\n"
          print " old: "
          if nonmatch.old.error == 'not_found'
            print "MISSING"
          else
            print util.inspect(nonmatch.old)
          print "\n\n"
        if !options.update
          print "use --update flag to update these.\n\n"
        else
          print "updating...\n"
          for nonmatch in unmatched
            couch.updateDesignDocument nonmatch.name, nonmatch.design, (err,body,headers) ->
              if err
                print "ERROR:\n"
                print util.inspect(err),"\n\n"
              else
                print "SUCCESS:\n"
                print util.inspect(body),"\n\n"
          
  

  

task 'kueadmin', 'launch kue admin server', (options) ->
  redis = require "redis"
  kue = require "kue"
  process.env.REDISTOGO_URL = "redis://redistogo:101ef0f223aa403f910a42d041139608@barracuda.redistogo.com:9318/"
  url = require("url").parse(process.env.REDISTOGO_URL)
  kue.redis.createClient = ->
    client = redis.createClient url.port, url.hostname
    client.auth url.auth.split(':')[1]
    client
  kue.app.listen(3000)
  console.log('listening on port 3000')
  
  
task 'redisinfo', 'show redis info', (options) ->
  redis = require "redis"
  url = require("url").parse("redis://redistogo:101ef0f223aa403f910a42d041139608@barracuda.redistogo.com:9318/")
  client = redis.createClient url.port, url.hostname
  client.auth url.auth.split(':')[1]
  client.on "ready", ->
    print require("util").inspect(client.server_info)
      
  
task 'redisflush', 'flush redis db', (options) ->
  redis = require "redis"
  url = require("url").parse("redis://redistogo:101ef0f223aa403f910a42d041139608@barracuda.redistogo.com:9318/")
  client = redis.createClient url.port, url.hostname
  client.auth url.auth.split(':')[1]
  client.on "ready", ->
    client.flushdb()

task 'rediskeys', 'show redis db keys', (options) ->
  redis = require "redis"
  util = require "util"
  url = require("url").parse("redis://redistogo:101ef0f223aa403f910a42d041139608@barracuda.redistogo.com:9318/")
  client = redis.createClient url.port, url.hostname
  client.auth url.auth.split(':')[1]
  client.on "ready", ->
    client.keys "*",(err,res) ->
      print err
      print util.inspect(res)
  

task 'qlist','list queues on ironmq',(options) ->
  process.env.IRON_MQ_TOKEN = '0uCkfFWlFX3LgucfEK8M6_LBJSM'
  process.env.IRON_MQ_PROJECT_ID ='4f315ebe5023e80f05000031'
  mq = require "ironmq"
  mq = mq process.env.IRON_MQ_TOKEN
  mq.list (err, obj) ->
    console.log "obj: #{JSON.stringify obj}"
    
task 'qput','put something to queue on ironmq',(options) ->
  process.env.IRON_MQ_TOKEN = '0uCkfFWlFX3LgucfEK8M6_LBJSM'
  process.env.IRON_MQ_PROJECT_ID ='4f315ebe5023e80f05000031'
  mq = require "ironmq"
  mq = mq process.env.IRON_MQ_TOKEN
  mq = mq.projects process.env.IRON_MQ_PROJECT_ID
  mq = mq.queues 'test'
  mq.put 'hello world', (err,obj) ->
    console.log "obj: #{JSON.stringify obj}"
    
task 'qget','get something from ironmq queue',(options) ->
  process.env.IRON_MQ_TOKEN = '0uCkfFWlFX3LgucfEK8M6_LBJSM'
  process.env.IRON_MQ_PROJECT_ID ='4f315ebe5023e80f05000031'
  mq = require "ironmq"
  mq = mq process.env.IRON_MQ_TOKEN
  mq = mq.projects process.env.IRON_MQ_PROJECT_ID
  mq = mq.queues 'test'
  mq.get (err,obj) ->
    console.log "obj: #{JSON.stringify obj}"
    
# obj: [{"id":"4f31639652549a04ab001c64","timeout":60,"body":"hello world"}]

task 'qdel','delete something from ironmq queue',(options) ->
  process.env.IRON_MQ_TOKEN = '0uCkfFWlFX3LgucfEK8M6_LBJSM'
  process.env.IRON_MQ_PROJECT_ID ='4f315ebe5023e80f05000031'
  mq = require "ironmq"
  mq = mq process.env.IRON_MQ_TOKEN
  mq = mq.projects process.env.IRON_MQ_PROJECT_ID
  mq = mq.queues 'test'
  mq.del "4f31639652549a04ab001c64", (err,obj) ->
    console.log "obj: #{JSON.stringify obj}"

