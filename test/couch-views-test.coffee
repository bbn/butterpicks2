couch = require "../lib/couch"  

exports.testGetUserByFacebookId = (test) ->
  facebookId = "gerbil"
  couch.db.view "facebookDocs","allByFacebookId", { key:facebookId }, (err,body,headers) ->
    test.equal err, null

    #TODO more

    test.done()