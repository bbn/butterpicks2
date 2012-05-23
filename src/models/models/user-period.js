var UserPeriod = Backbone.Model.extend(
{
  //instance properties
  
  defaults : {
    
    user: null,
    period: null,
    
    league: null,
    leagueAbbreviation: null,
    points: null,
    level: null,
    pointsUntilNextLevel: null,
    stars: null,
    ribbons: null,
    medals: null,
	
  	picks: null
  },
  
  initialize : function() {
    var period = this.get("period");
    var self = this;
    if (period) {
      if (period.get("games") != null) {
        self.updatePicks();
      }
      period.on("change:games", function() {
        self.updatePicks();
      });
    }
  	if (!this.get("points")) {
      if ((this.get("period").get("gaeKey")) && (this.get("user").get("gaeKey"))) {
    		this.updatePoints();
      } else {
        this.get("period").on("change:gaeKey", function() {
          self.updatePoints();
        });
        this.get("user").on("change:gaeKey", function() {
          self.updatePoints();
        });
      }
  	}
  },
  
  updatePoints : function() {
    var self = this;
    $.getJSON('/api/participant-period', { period_key: this.get("period").get("gaeKey"),
                                           participant_key: this.get("user").get("gaeKey") },
      function(data) {
        self.set({gaeKey:data.key, points:data.points});
      }
    )
  },
  
  updatePicks : function() {
    var user = this.get("user");
    if (!user) {
      return;
    }
    var period = this.get("period");
    var games = period.get("games");
    var newPicks = [];
    for (var i=0;i<games.length;i++) {
      newPicks.push(new Pick({
        user : user,
        game : games[i]
      }));
    }
    this.set({ picks : newPicks });
  }
  

});