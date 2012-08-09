fs = require 'fs'
util = require 'util'

{print} = require 'util'
{spawn} = require 'child_process'

PRODUCTION_CLOUDANT_URL = "https://app1945930.heroku:w2sh1F5WdYdbThudBIyvCuIG@app1945930.heroku.cloudant.com"

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
  x = spawn 'browserify', ['lib/models/models.js','-o','static/js/models.js']
  x.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  x.stdout.on 'data', (data) ->
    print data.toString()
  x.on 'exit', (code) ->
    if code is 0
      print "browserified!\n"
    callback(code)
    

option '-n', '--notest', 'do not run tests'
    
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
          invoke("freshtest") unless options.notest
  

task 'freshtest', 'Run tests, wiping test db first', (options) ->
  process.env.freshtest = true
  process.env.testing = true
  process.env.testingDbName = 'picks-testing'
  nano = require("nano") "http://localhost:5984"
  nano.db.destroy "picks-testing", (err,body) ->
    nano.db.create "picks-testing", ->
      updateDesignDocuments {update:true,silent:true}, (err,_) ->
        invoke "jscoverage"


task 'jscoverage', 'Create js-coverage versions of lib files', (options) ->
  d = spawn "rm", ["-rf","lib-cov"]
  d.stderr.on "data", (data) ->
    process.stderr.write data.toString()
  d.stdout.on 'data', (data) ->
    print data
  d.on 'exit', (code) ->
    cov = spawn "jscoverage", ["lib","lib-cov"]
    cov.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    cov.stdout.on 'data', (data) ->
      print data
    cov.on 'exit', (code) ->
      print "\n+++ lib-cov updated.\n\n"
      invoke "jsmeter"

task "jsmeter", "generate code metrics using jsmeter", (options) ->
  x = spawn "./node_modules/node-jsmeter/bin/jsmeter.js", ["-o","./covershot/jsmeter/","./lib/"]
  x.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  x.stdout.on 'data', (data) ->
    print data
  x.on 'exit', (code) ->
    print "\n+++ code metrics updated.\n\n"
    invoke "test"

option '-tf', '--testfile [FILE]', 'test file to run'

task 'test', 'Run tests', (options) ->
  process.env.testing = true
  process.env.testingDbName = 'picks-testing'
  testfiles = ['test']
  testfiles = [options.testfile] if options.testfile
  tests = spawn "./node_modules/nodeunit/bin/nodeunit", testfiles
  tests.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  tests.stdout.on 'data', (data) ->
    print data
  tests.on 'exit', (code) ->
    print "\n+++ Tests finished. Code: #{code}\n\n"
    invoke "coverage-report"


task 'coverage-report', "Generate a coverage report", (options) ->
  x = spawn "./node_modules/covershot/bin/covershot", ["covershot/data","-f","html","-f","clover","-f","json"]
  x.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  x.stdout.on 'data', (data) ->
    print data
  x.on 'exit', (code) ->
    print "\n+++ coverage report generated.\n"
    print "To view: open covershot/index.html\n\n"



  

   
  

# compare and optionally update design documents

updateDesignDocuments = (options,callback) ->
  pr = (s) ->
    print s unless options.silent
  couch = require "./lib/couch" 
  couch.identifyUnmatchedDesignDocs (err,unmatched) ->
    return callback(err) if err
    return pr("no unmatched design documents.\n") unless unmatched.length > 0
    pr "\nunmatched design documents:\n\n"
    for nonmatch in unmatched
      pr nonmatch.name,"\n"
      pr " new: ",util.inspect(nonmatch.design),"\n"
      pr " old: "
      if nonmatch.old 
        pr util.inspect(nonmatch.old)
      else
        pr "MISSING"
      pr "\n\n"
    return pr("+++ use --update flag to update these.\n\n") unless options.update or process.env.freshtest
    pr "updating...\n"
    count = unmatched.length
    for nonmatch in unmatched
      couch.updateDesignDocument nonmatch.name, nonmatch.design, (err,body,headers) ->
        if err
          pr "ERROR:\n"
          pr util.inspect(err),"\n\n"
          return callback(err)
        pr "SUCCESS:\n"
        pr util.inspect(body),"\n\n"
        return callback(null) unless --count


option '-p', '--production', 'use production couchdb'
option '-t', '--testing', 'use testing couchdb'
option '-u', '--update', 'update design documents (careful!)'

task 'couchdesign', 'check the design of the couchdb document', (options) ->
  if options.testing
    process.env.testing = true
    process.env.testingDbName = 'picks-testing'
  process.env.CLOUDANT_URL = PRODUCTION_CLOUDANT_URL if options.production
  updateDesignDocuments options, (err,info) ->
    console.log "done"
        
  

  

