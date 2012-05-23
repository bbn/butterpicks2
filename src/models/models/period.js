var Period = Backbone.Model.extend(
  {
    //instance properties
  
    defaults : {
      
      league: null,
      name: null,
      category : null,
      startDate : null,
      endDate : null,
      gaeKey : null,
  	  userCount : null,
      games : null
	    
    },
    
    loadBaseGames : function() {
      var league = this.get("league");
      var abbrev = league.get("abbreviation");
      var date = this.get("startDate");
      var self = this;
      $.getJSON('/api/games/base', { league:abbrev, year:date.getFullYear(), month:date.getMonth()+1, day:date.getDate() },
        function(data) {
          var newGames = [];
          for (var i=0;i<data.length;i++) {
            var game = new Game({
              awayName: data[i].away_name,
              awayScore: data[i].away_score,
              awayValue: data[i].away_value,
              basePeriodGaeKey: data[i].base_period_key,
              statsKey: data[i].butterstats_key,
              drawValue: data[i].draw_value,
              final: data[i].final,
              homeName: data[i].home_name,
              homeScore: data[i].home_score,
              homeValue: data[i].home_value,
              gaeKey: data[i].key,
              league: league,
              legit: data[i].legit,
              postponed: data[i].postponed,
              secondsUntilDeadline: data[i].seconds_until_deadline,
              startDate: new Date(data[i].starts_at*1000),
              status: data[i].status
            });
            newGames.push(game);
          }
          self.set({games:newGames});
        }
      );
    }


  },
  {
    //class properties 
  }
);
