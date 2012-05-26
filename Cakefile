fs = require 'fs'
util = require 'util'

{print} = require 'util'
{spawn} = require 'child_process'

PRODUCTION_CLOUDANT_URL = "nonsense"
###
TODO replace "nonsense" with new cloudant URL instance
eg: the pools cloudant URL was
https://app1777531.heroku:885tk871iqj5ooraJQC4L5gS@app1777531.heroku.cloudant.com"
###

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
  process.env.testingDbName = 'picks-testing'
  tests = spawn "./node_modules/nodeunit/bin/nodeunit", ['test']
  tests.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  tests.stdout.on 'data', (data) ->
    print data
  tests.on 'exit', (code) ->
    print "\n+++ Tests finished.\n\n"    
  


# compare and optionally update design documents

option '-p', '--production', 'use production couchdb'
option '-t', '--testing', 'use testing couchdb'
option '-u', '--update', 'update design documents (careful!)'

task 'couchdesign', 'check the design of the couchdb document', (options) ->
  if options.testing
    process.env.testing = true
    process.env.testingDbName = 'picks-testing'
  process.env.CLOUDANT_URL = PRODUCTION_CLOUDANT_URL if options.production 
  couch = require "./lib/couch" 
  couch.identifyUnmatchedDesignDocs (err,unmatched) ->
    return print(util.inspect(err)) if err
    if unmatched.length == 0
      print "no unmatched design documents.\n"
    else
      print "\nunmatched design documents:\n\n"
      for nonmatch in unmatched
        print nonmatch.name,"\n"
        print " new: ",util.inspect(nonmatch.design),"\n"
        print " old: "
        if nonmatch.old 
          print util.inspect(nonmatch.old)
        else
          print "MISSING"
        print "\n\n"
      if !options.update
        print "+++ use --update flag to update these.\n\n"
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
        
  

  

