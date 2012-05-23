var Pick = Backbone.Model.extend(
  {
    //instance properties
  
    defaults : {
			user: null,
			game: null,
			gaekey: null,
			
			home: null,
			away: null,
			draw: null,
			butter: null,
			
			freebie: null,
			useless: null,
			
			updating: false
			
    },
		
		initialize : function() {
      var self = this;
			var user = this.get("user");
			var game = this.get("game");
			if (user && game) {
        if (user.get("gaeKey")) {
  				self.update();
        } else {
          user.on("change:gaeKey", function(gaeKey) {
            self.update();
          });
        }
			}
			this.on("change:butter",function() {
				var user = this.get("user");
        if ((user) && (this.previous("butter") != null)) {
				  user.updateButters();
				}
			},this);
		},
		
		save : function(action) {
			//TODO
			//currently logic lives on server for the controls and how they respond to touches.
			//obvs that's crazy.
		
			this.update(action);
		},
		
		
		
		
		update : function(action) {
			this.set({updating:true});
			var self = this;  
      var method = 'GET';
			var user = this.get("user");
			var userGaeKey = user.get("gaeKey");
      var facebookUid = user.get("facebookUid");
			var game = this.get("game");
      var args = 'participant_key='+userGaeKey+'&facebook_uid='+facebookUid+'&game_key='+game.get("gaeKey");
      if (action) {
        method='POST'
        if (action=='home') {
			    if (this.get("home")) {
			      args += '&home=false';
			    } else {
			      args += '&home=true';
			    }
			  } else if (action=='away') {
			    if (this.get("away")) {
			      args += '&away=false';
			    } else {
			      args += '&away=true';
			    }
			  } else if (action=='draw') {
			    if (this.get("draw")) {
			      args += '&draw=false';
			    } else {
			      args += '&draw=true';
			    }
			  } else if (action=='butter') {
			    if (this.get("butter")) {
			      args += '&butter=false';
			    } else {
				    args += '&butter=true';
			    }
			  }
			}
      $.ajax({
        type:method,
        url:"/api/pick",
        data:args,
        dataType:'json',
        success: function(data) {
					self.set({
						away: data.away,
						//away_name: "Sabres"
						//away_score: 0
						//away_value: 2.9
						butter: data.butter,
						//can_edit: true
						//deserves_points: false
						draw: data.draw,
						//draw_value: null
						//failed: false
						//final: false
						freebie: data.freebie,
						//game_key: "agtidXR0ZXJwaWNrc3INCxIER2FtZRi29OQCDA"
						//game_status: null
						home: data.home,
						//home_name: "Ducks"
						//home_score: 0
						//home_value: 1.5
						//participant_key: "agtidXR0ZXJwaWNrc3IRCxILUGFydGljaXBhbnQYBAw"
						gaeKey: data.pick_key,
						//points_earned: 0,
						//potential_loss_value: 0
						//potential_win_value: 1.5
						//risk: false
						//safety: false
						//safety_value: 1.5
						//seconds_until_deadline: 13594
						useless: data.useless,
						updating: false
					});
				}
			})
		}

  },
  {
    //class properties 
  }
);
