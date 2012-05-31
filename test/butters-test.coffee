util = require "util"
journey = require "journey"
controllers = require "../lib/controllers"
mockRequest = require "../node_modules/journey/lib/journey/mock-request"
mock = mockRequest.mock controllers.router
journey.env = "test"

Backbone = require "backbone"
bbCouch = require "../lib/backbone-couch"
Backbone.sync = bbCouch.sync
models = require "../lib/models"
User = models.User
ButterTransaction = models.ButterTransaction


exports.testButters = 

  setUp: (callback) ->
    @userData = 
      facebookId: 129837892
      email: "blergle@zsazsa.za"
    u = new User(@userData)
    u.save u.toJSON(),
      error: (model,response) -> console.log util.inspect(response)
      success: (model,response) =>
        @userModel = model
        callback()

  testTransactionCreate: (test) ->
    tr = new ButterTransaction
      userId: @userModel.id
      amount: 1
      createdDate: new Date()
      note: "daily butter"
    tr.save tr.toJSON(),
      error: (model,response) -> console.log util.inspect response
      success: (model,response) =>
        test.ok model
        test.ok model.id
        test.equal model.get("userId"),@userModel.id
        test.equal model.get("doctype"),"ButterTransaction", "proper doctype"
        model.destroy
          error: (model,response) -> console.log util.inspect response
          success: -> test.done()

  testButtersGet: (test) ->
    x = mock.get "/butters?userId=#{@userModel.id}", { accept: "application/json" }
    x.on 'success', (response) =>
      test.ok response
      test.equal response.status, 200 
      test.equal response.body.userId,@userModel.id, "same user id"
      test.equal response.body.butters,null, "should have null butters"
      tr1 = new ButterTransaction
        userId: @userModel.id
        amount: 1
        createdDate: new Date()
        note: "daily butter"
      tr1.save tr1.toJSON(),
        error: (model,response) -> console.log util.inspect response
        success: (model,response) =>
          tr1 = model
          y = mock.get "/butters?userId=#{@userModel.id}", { accept: "application/json" }
          y.on 'success', (response) =>
            test.equal response.status, 200 
            test.equal response.body.userId,@userModel.id, "same user id"
            test.equal response.body.butters,1, "should have 1 butter. #{util.inspect response.body.butters}"
            tr2 = new ButterTransaction
              userId: @userModel.id
              amount: 100
              createdDate: new Date()
              note: "big ol prize"
            tr2.save tr2.toJSON(),
              error: (model,response) -> console.log util.inspect response
              success: (model,response) =>
                tr2 = model
                z = mock.get "/butters?userId=#{@userModel.id}", { accept: "application/json" }
                z.on 'success', (response) =>
                  test.equal response.status, 200 
                  test.equal response.body.userId,@userModel.id, "same user id"
                  test.equal response.body.butters,101, "should have 101 butters"
                  tr3 = new ButterTransaction
                    userId: @userModel.id
                    pickId: "5127ghjkh12983812" #TODO eventually put in real pick here
                    amount: -1
                    createdDate: new Date()
                    note: "pick"
                  tr3.save tr3.toJSON(),
                    error: (model,response) -> console.log util.inspect response
                    success: (model,response) =>
                      tr3 = model
                      w = mock.get "/butters?userId=#{@userModel.id}", { accept: "application/json" }
                      w.on 'success', (response) =>
                        test.equal response.status, 200 
                        test.equal response.body.userId,@userModel.id, "same user id"
                        test.equal response.body.butters,100, "should have 100 butters"
                        tr1.destroy
                          error: (model,response) -> console.log util.inspect response
                          success: =>
                            tr2.destroy
                              error: (model,response) -> console.log util.inspect response
                              success: =>
                                tr3.destroy
                                  error: (model,response) -> console.log util.inspect response
                                  success: =>
                                    test.done()

  testButtersGetWithInvalidUserId: (test) ->
    x = mock.get "/butters", { accept: "application/json" }
    x.on 'success', (response) ->
      test.equal response.status,400
      test.equal response.body.error,"no userId param"
      missingId = 673216753125673
      x = mock.get "/butters?userId=#{missingId}", { accept: "application/json" }
      x.on 'success', (response) ->
        test.equal response.status,200
        test.equal response.body.userId,missingId
        test.equal response.body.butters,null
        test.done()


  tearDown: (callback) ->
    @userModel.destroy
      error: (model,response) -> console.log util.inspect response
      success: -> callback()