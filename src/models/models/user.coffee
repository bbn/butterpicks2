Backbone = require "backbone"

module.exports = class User extends Backbone.Model

  idAttribute: "_id"

  defaults:
    email: null
    createdAt: JSON.stringify(new Date())
    facebookId: null
    name: null
    butters: null
    lifetimeUserPeriods: null

  #  loadData : function(callback) {
  #    var self = this;
  #    $.getJSON('/api/participant', { facebook_uid:this.get("facebookUid"), email:this.get("email") },
  #      function(data) {
  #        var ups = [];
  #        self.set({
  #          gaeKey: data.participant_key,
  #          createdAt: data.created_at
  #        });
  #        for (var i=0;i<data.lifetime_participant_periods.length;i++) {
  #          var lpp = data.lifetime_participant_periods[i];
  #          ups.push(new UserPeriod({
  #            leagueAbbreviation : lpp.league,
  #            points : lpp.points,
  #            level : lpp.level,
  #            pointsUntilNextLevel : lpp.points_until_next_level,
  #            stars : lpp.stars,
  #            ribbons : lpp.ribbons,
  #            medals : lpp.medals
  #          }));
  #        }
  #        self.set({ lifetimeUserPeriods:ups });
  #				self.updateButters();
  #        if (callback) {
  #          callback(self);
  #        }
  #      }
  #    );
  #  },
  #  
  #  updateButters : function(callback) {
  #    var self = this;
  #		var pKey = self.get('gaeKey');
  #		if (pKey) {
  #	    $.getJSON('/api/butters', { participant_key : pKey },
  #	      function(data) {
  #	        self.set({ butters: data });
  #	      }
  #	    )
  #		}
  #  }
  #  
  #},
  #{
  #
  #  //class properties
  #  
  #  createFromFacebookId: function(params,callback) {
  #    var user = new User(params);
  #    user.loadData(callback);
  #    return user;
  #  }
  #}
  #);