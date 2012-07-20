_ = require "underscore"
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
UserPeriod = models.UserPeriod
Prize = models.Prize

logErrorResponse = (message) ->
  (model,response) ->
    console.log "#{message} -> response: #{require('util').inspect response}"

exports.testConditions = (test) ->
	prize = new Prize
		leagueId: "dasjhdkjsahkdjhaskjh"
		name: "100 picks made"
		pointValue: 100
		eligibleConditions: [{metric:"maximumEligibleUserPickCount",operator:">=",value:100}]
		possibleConditions: [{metric:"maximumPossibleUserPickCount",operator:">=",value:100}]
		successConditions: [{metric:"currentUserPickCount",operator:">=",value:100},{metric:"allGamesFinal",operator:"==",value:true}]
		failConditions: [{metric:"allGamesFinal",operator:"==",value:true},{metric:"currentUserPickCount",operator:"<",value:100}]
	metrics = 
		allGamesFinal: false
		currentUserPickCount: 90
		maximumEligibleUserPickCount: 105
		maximumPossibleUserPickCount: 105
	test.equal prize.eligible(metrics),true,"eligible"
	test.equal prize.possible(metrics),true,"possible"
	test.equal prize.success(metrics),false,"success"
	test.equal prize.fail(metrics),false,"fail"

	metrics = 
		allGamesFinal: false
		currentUserPickCount: 105
		maximumEligibleUserPickCount: 105
		maximumPossibleUserPickCount: 105
	test.equal prize.eligible(metrics),true,"eligible"
	test.equal prize.possible(metrics),true,"possible"
	test.equal prize.success(metrics),false,"success"
	test.equal prize.fail(metrics),false,"fail"
	
	metrics = 
		allGamesFinal: true
		currentUserPickCount: 105
		maximumEligibleUserPickCount: 105
		maximumPossibleUserPickCount: 105
	test.equal prize.eligible(metrics),true,"eligible"
	test.equal prize.possible(metrics),true,"possible"
	test.equal prize.success(metrics),true,"success"
	test.equal prize.fail(metrics),false,"fail"
	
	metrics = 
		allGamesFinal: true
		currentUserPickCount: 90
		maximumEligibleUserPickCount: 105
		maximumPossibleUserPickCount: 105
	test.equal prize.eligible(metrics),true,"eligible"
	test.equal prize.possible(metrics),false,"possible"
	test.equal prize.success(metrics),false,"success"
	test.equal prize.fail(metrics),true,"fail"
	
	metrics = 
		allGamesFinal: false
		currentUserPickCount: 92
		maximumEligibleUserPickCount: 97
		maximumPossibleUserPickCount: 97
	test.equal prize.eligible(metrics),false,"eligible"
	test.equal prize.possible(metrics),false,"possible"
	test.equal prize.success(metrics),false,"success"
	test.equal prize.fail(metrics),false,"fail"

	metrics = 
		allGamesFinal: false
		currentUserPickCount: 92
		maximumEligibleUserPickCount: 101
		maximumPossibleUserPickCount: 97
	test.equal prize.eligible(metrics),true,"eligible"
	test.equal prize.possible(metrics),false,"possible"
	test.equal prize.success(metrics),false,"success"
	test.equal prize.fail(metrics),false,"fail"
	
	test.done()



exports.testFetchAllForLeagueId = (test) ->
	@league = new models.League
	@league.save @league.toJSON(),
		error: logErrorResponse "@league.save"
		success: =>
			@prize1 = new Prize
				leagueId: @league.id
				name: "prize1"
				pointValue: 1000
				eligibleConditions: [{metric:"maximumEligibleUserPickCount",operator:">=",value:100}]
				possibleConditions: [{metric:"maximumPossibleUserPickCount",operator:">=",value:100}]
				successConditions: [{metric:"currentUserPickCount",operator:">=",value:100},{metric:"allGamesFinal",operator:"==",value:true}]
				failConditions: [{metric:"allGamesFinal",operator:"==",value:true},{metric:"currentUserPickCount",operator:"<",value:100}]
			@prize1.save @prize1.toJSON(),
				error: logErrorResponse "@prize1.save"
				success: =>
					@prize2 = new Prize
						leagueId: @league.id
						name: "prize2"
						pointValue: 100
						eligibleConditions: []
						possibleConditions: [{metric:"maximumPossibleUserPickCount",operator:">=",value:100}]
						successConditions: [{metric:"currentUserPickCount",operator:">=",value:100},{metric:"allGamesFinal",operator:"==",value:true}]
						failConditions: [{metric:"allGamesFinal",operator:"==",value:true},{metric:"currentUserPickCount",operator:"<",value:100}]
					@prize2.save @prize2.toJSON(),
						error: logErrorResponse "@prize2.save"
						success: =>
							@prize3 = new Prize
								leagueId: "someotherleagueid"
								name: "prize3"
								pointValue: 10
								eligibleConditions: [{metric:"maximumEligibleUserPickCount",operator:">=",value:100}]
								possibleConditions: []
								successConditions: []
								failConditions: [{metric:"allGamesFinal",operator:"==",value:true},{metric:"currentUserPickCount",operator:"<",value:100}]
							@prize3.save @prize3.toJSON(),
								error: logErrorResponse "@prize3.save"
								success: =>
									Prize.fetchAllForLeague @league,
										error: logErrorResponse "Prize.fetchAllForLeague"
										success: (prizes) =>
											test.equal prizes.length,2
											test.done()
