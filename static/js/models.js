var require = function (file, cwd) {
    var resolved = require.resolve(file, cwd || '/');
    var mod = require.modules[resolved];
    if (!mod) throw new Error(
        'Failed to resolve module ' + file + ', tried ' + resolved
    );
    var res = mod._cached ? mod._cached : mod();
    return res;
}

require.paths = [];
require.modules = {};
require.extensions = [".js",".coffee"];

require._core = {
    'assert': true,
    'events': true,
    'fs': true,
    'path': true,
    'vm': true
};

require.resolve = (function () {
    return function (x, cwd) {
        if (!cwd) cwd = '/';
        
        if (require._core[x]) return x;
        var path = require.modules.path();
        cwd = path.resolve('/', cwd);
        var y = cwd || '/';
        
        if (x.match(/^(?:\.\.?\/|\/)/)) {
            var m = loadAsFileSync(path.resolve(y, x))
                || loadAsDirectorySync(path.resolve(y, x));
            if (m) return m;
        }
        
        var n = loadNodeModulesSync(x, y);
        if (n) return n;
        
        throw new Error("Cannot find module '" + x + "'");
        
        function loadAsFileSync (x) {
            if (require.modules[x]) {
                return x;
            }
            
            for (var i = 0; i < require.extensions.length; i++) {
                var ext = require.extensions[i];
                if (require.modules[x + ext]) return x + ext;
            }
        }
        
        function loadAsDirectorySync (x) {
            x = x.replace(/\/+$/, '');
            var pkgfile = x + '/package.json';
            if (require.modules[pkgfile]) {
                var pkg = require.modules[pkgfile]();
                var b = pkg.browserify;
                if (typeof b === 'object' && b.main) {
                    var m = loadAsFileSync(path.resolve(x, b.main));
                    if (m) return m;
                }
                else if (typeof b === 'string') {
                    var m = loadAsFileSync(path.resolve(x, b));
                    if (m) return m;
                }
                else if (pkg.main) {
                    var m = loadAsFileSync(path.resolve(x, pkg.main));
                    if (m) return m;
                }
            }
            
            return loadAsFileSync(x + '/index');
        }
        
        function loadNodeModulesSync (x, start) {
            var dirs = nodeModulesPathsSync(start);
            for (var i = 0; i < dirs.length; i++) {
                var dir = dirs[i];
                var m = loadAsFileSync(dir + '/' + x);
                if (m) return m;
                var n = loadAsDirectorySync(dir + '/' + x);
                if (n) return n;
            }
            
            var m = loadAsFileSync(x);
            if (m) return m;
        }
        
        function nodeModulesPathsSync (start) {
            var parts;
            if (start === '/') parts = [ '' ];
            else parts = path.normalize(start).split('/');
            
            var dirs = [];
            for (var i = parts.length - 1; i >= 0; i--) {
                if (parts[i] === 'node_modules') continue;
                var dir = parts.slice(0, i + 1).join('/') + '/node_modules';
                dirs.push(dir);
            }
            
            return dirs;
        }
    };
})();

require.alias = function (from, to) {
    var path = require.modules.path();
    var res = null;
    try {
        res = require.resolve(from + '/package.json', '/');
    }
    catch (err) {
        res = require.resolve(from, '/');
    }
    var basedir = path.dirname(res);
    
    var keys = (Object.keys || function (obj) {
        var res = [];
        for (var key in obj) res.push(key)
        return res;
    })(require.modules);
    
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key.slice(0, basedir.length + 1) === basedir + '/') {
            var f = key.slice(basedir.length);
            require.modules[to + f] = require.modules[basedir + f];
        }
        else if (key === basedir) {
            require.modules[to] = require.modules[basedir];
        }
    }
};

require.define = function (filename, fn) {
    var dirname = require._core[filename]
        ? ''
        : require.modules.path().dirname(filename)
    ;
    
    var require_ = function (file) {
        return require(file, dirname)
    };
    require_.resolve = function (name) {
        return require.resolve(name, dirname);
    };
    require_.modules = require.modules;
    require_.define = require.define;
    var module_ = { exports : {} };
    
    require.modules[filename] = function () {
        require.modules[filename]._cached = module_.exports;
        fn.call(
            module_.exports,
            require_,
            module_,
            module_.exports,
            dirname,
            filename
        );
        require.modules[filename]._cached = module_.exports;
        return module_.exports;
    };
};

if (typeof process === 'undefined') process = {};

if (!process.nextTick) process.nextTick = (function () {
    var queue = [];
    var canPost = typeof window !== 'undefined'
        && window.postMessage && window.addEventListener
    ;
    
    if (canPost) {
        window.addEventListener('message', function (ev) {
            if (ev.source === window && ev.data === 'browserify-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);
    }
    
    return function (fn) {
        if (canPost) {
            queue.push(fn);
            window.postMessage('browserify-tick', '*');
        }
        else setTimeout(fn, 0);
    };
})();

if (!process.title) process.title = 'browser';

if (!process.binding) process.binding = function (name) {
    if (name === 'evals') return require('vm')
    else throw new Error('No such module')
};

if (!process.cwd) process.cwd = function () { return '.' };

if (!process.env) process.env = {};
if (!process.argv) process.argv = [];

require.define("path", function (require, module, exports, __dirname, __filename) {
function filter (xs, fn) {
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (fn(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length; i >= 0; i--) {
    var last = parts[i];
    if (last == '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Regex to split a filename into [*, dir, basename, ext]
// posix version
var splitPathRe = /^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/;

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
var resolvedPath = '',
    resolvedAbsolute = false;

for (var i = arguments.length; i >= -1 && !resolvedAbsolute; i--) {
  var path = (i >= 0)
      ? arguments[i]
      : process.cwd();

  // Skip empty and invalid entries
  if (typeof path !== 'string' || !path) {
    continue;
  }

  resolvedPath = path + '/' + resolvedPath;
  resolvedAbsolute = path.charAt(0) === '/';
}

// At this point the path should be resolved to a full absolute path, but
// handle relative paths to be safe (might happen when process.cwd() fails)

// Normalize the path
resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
var isAbsolute = path.charAt(0) === '/',
    trailingSlash = path.slice(-1) === '/';

// Normalize the path
path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }
  
  return (isAbsolute ? '/' : '') + path;
};


// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    return p && typeof p === 'string';
  }).join('/'));
};


exports.dirname = function(path) {
  var dir = splitPathRe.exec(path)[1] || '';
  var isWindows = false;
  if (!dir) {
    // No dirname
    return '.';
  } else if (dir.length === 1 ||
      (isWindows && dir.length <= 3 && dir.charAt(1) === ':')) {
    // It is just a slash or a drive letter with a slash
    return dir;
  } else {
    // It is a full dirname, strip trailing slash
    return dir.substring(0, dir.length - 1);
  }
};


exports.basename = function(path, ext) {
  var f = splitPathRe.exec(path)[2] || '';
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPathRe.exec(path)[3] || '';
};

});

require.define("/models/game.js", function (require, module, exports, __dirname, __filename) {
var Game = Backbone.Model.extend(
  {
    //instance properties
  
    defaults : {

      awayName: null,
      awayScore: null,
      awayValue: null,
      basePeriodGaeKey: null,
      statsKey: null,
      drawValue: null,
      final: null,
      homeName: null,
      homeScore: null,
      homeValue: null,
      gaeKey: null,
      league: null,
      legit: null,
      postponed: null,
      secondsUntilDeadline: null,
      startDate: null,
      status: null
	    
    }

  },
  {
    //class properties 
  }
);

});

require.define("/models/league.js", function (require, module, exports, __dirname, __filename) {
var League = Backbone.Model.extend(
{
  //instance properties
  
  defaults : {
	  imageUrl : null,
	  abbreviation : null,
	  name: null
  },
  
  drawsPossible : function() {
	  if (this.get("abbreviation")=="EPL")
  	  return true;
    return false;
  }

},
{

  //class properties
  
 
}
);

});

require.define("/models/period.js", function (require, module, exports, __dirname, __filename) {
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

});

require.define("/models/pick.js", function (require, module, exports, __dirname, __filename) {
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

});

require.define("/models/user-period.js", function (require, module, exports, __dirname, __filename) {
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
});

require.define("/models/user.js", function (require, module, exports, __dirname, __filename) {
var User = Backbone.Model.extend(
{
  //instance properties
  defaults : {
    email: null,
    facebookUid: null,
    name: null,
    createdAt: null,
    gaeKey: null,
    butters: null,
    lifetimeUserPeriods: null
  },
  
  loadData : function(callback) {
    var self = this;
    $.getJSON('/api/participant', { facebook_uid:this.get("facebookUid"), email:this.get("email") },
      function(data) {
        var ups = [];
        self.set({
          gaeKey: data.participant_key,
          createdAt: data.created_at
        });
        for (var i=0;i<data.lifetime_participant_periods.length;i++) {
          var lpp = data.lifetime_participant_periods[i];
          ups.push(new UserPeriod({
            leagueAbbreviation : lpp.league,
            points : lpp.points,
            level : lpp.level,
            pointsUntilNextLevel : lpp.points_until_next_level,
            stars : lpp.stars,
            ribbons : lpp.ribbons,
            medals : lpp.medals
          }));
        }
        self.set({ lifetimeUserPeriods:ups });
				self.updateButters();
        if (callback) {
          callback(self);
        }
      }
    );
  },
  
  updateButters : function(callback) {
    var self = this;
		var pKey = self.get('gaeKey');
		if (pKey) {
	    $.getJSON('/api/butters', { participant_key : pKey },
	      function(data) {
	        self.set({ butters: data });
	      }
	    )
		}
  }
  
},
{

  //class properties
  
  createFromFacebookId: function(params,callback) {
    var user = new User(params);
    user.loadData(callback);
    return user;
  }
}
);
});

require.define("/models.coffee", function (require, module, exports, __dirname, __filename) {
    (function() {
  var models;

  models = exports;

  models.Game = require("./models/game");

  models.League = require("./models/league");

  models.Period = require("./models/period");

  models.Pick = require("./models/pick");

  models.UserPeriod = require("./models/user-period");

  models.User = require("./models/user");

}).call(this);

});
require("/models.coffee");
