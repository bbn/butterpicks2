util = require "util"
request = require "request"
couch = require "./couch"
models = require "./models"
Game = models.Game


exports.getMostRecentlyUpdatedGameDate = getMostRecentlyUpdatedGameDate = (options) ->
  viewParams =
    descending: true
    limit: 1
  couch.db.view "games","mostRecentlyUpdated", viewParams, (err,body,headers) ->
    return options.error null,err if err
    date = if body.rows.length then new Date(JSON.parse(body.rows[0].key)) else null
    options.success date, body


pollInterval = null
exports.poll (interval) ->
  pollInterval = interval if interval
  setTimeout(updateGames({poll:true}), pollInterval) if pollInterval


updateGames = (options) ->
  getMostRecentlyUpdatedGameDate
    error: (_,error) ->
      console.log "!! error in getMostRecentlyUpdatedGameDate: #{util.inspect error}"
    success: (lastUpdatedGameDate,response) ->
      integerDate = parseInt(lastUpdatedGameDate.valueOf()/1000)
      statsUrl = "http://butterstats.appspot.com/api/getgamesrecentlyupdated?since=#{integerDate}"
      console.log "+++ fetching #{statsUrl}"
      requestParams = 
        uri: statsUrl
        json: true
      request.get requestParams, (error,response,body) ->
        console.log "returned body! #{body}"


        exports.poll() if options and options.poll


  # game_info = json.read(data.content)
  # self.response.out.write(str(len(game_info))+' to update.\n')
  # period_keys_to_update = {}
  # for info in game_info:
  #   #check league - do we want it?
  #   league = info['league']
  #   league_object = League.all().filter('abbreviation = ',league).get()
  #   if league_object is not None:
  #     statskey = info['key']
  #     g = Game.all().filter('butterstats_key = ',statskey).get()
  #     if not g:
  #       self.response.out.write("creating game...\n")
  #       g = Game()
  #       g.butterstats_key = statskey
  #     if g.starts_at and g.league:
  #       old_period = get_base_period(g.starts_at,g.league)
  #       old_key = key_for_number_of_games(g.starts_at,g.league)
  #     else:
  #       old_period = None
  #       old_key = None
  #     self.response.out.write('updating game...')
  #     g.away_name = self.convert_to_picks_name(info['away_team']['name'])
  #     g.home_name = self.convert_to_picks_name(info['home_team']['name'])
  #     g.league = info['league']      
  #     g.legit = info['legit']
  #     g.away_score = info['away_score']
  #     g.home_score = info['home_score']
  #     g.status = info['status']
  #     g.starts_at = datetime.fromtimestamp(info['starts_at'])        
  #     g.last_updated_at = datetime.fromtimestamp(info['updated_at'])
  #     g.put()
      
  #     new_period = get_base_period(g.starts_at,g.league)
  #     new_period.all_updated = False
  #     new_period.put()
  #     new_period.delete_cache()
  #     memcache.delete(key_for_number_of_games(g.starts_at,g.league))
  #     if g.final() or g.postponed(): 
  #       all_games_effectively_final = new_period.all_games_effectively_final()
  #       if all_games_effectively_final:
  #         period_keys_to_update[str(new_period.key())] = True
  #       else:
  #         period_keys_to_update[str(new_period.key())] = False
  #       custom_periods = get_superset_custom_periods(new_period.league,new_period.starts_at(),new_period.ends_at())
  #       for cp in custom_periods:
  #         period_keys_to_update[str(cp.key())] = False #TODO 
  #     if old_period:
  #       old_period.delete_cache()
  #       memcache.delete(old_key)
  # for k in period_keys_to_update:
  #   params = {'period_key':k, 'all_games_effectively_final':period_keys_to_update[k]}
  #   taskqueue.Task(method='GET',url='/update_participant_periods',params=params).add('updatepp')      



# class UpdateGamesHandler(BaseRequestHandler):
#   def convert_to_picks_name(self,name):
#     if name == 'Diamondbacks':
#       return 'Diamndbks'
#     elif name == 'Blue Bombers':
#       return 'Bombers'
#     return name
      
#   def get(self):
#     last_update_at = most_recently_updated_game().last_updated_at
#     last_update_at_i = int(mktime(last_update_at.timetuple()))
#     statsurl = 'http://butterstats.appspot.com/api/getgamesrecentlyupdated?since='+str(last_update_at_i)
#     logging.debug('fetching '+statsurl)
#     try:
#       data = urlfetch.fetch(statsurl)
#     except DownloadError:
#       logging.warning('failed to download from butterstats.')
#       return
#     game_info = json.read(data.content)
#     self.response.out.write(str(len(game_info))+' to update.\n')
#     period_keys_to_update = {}
#     for info in game_info:
#       #check league - do we want it?
#       league = info['league']
#       league_object = League.all().filter('abbreviation = ',league).get()
#       if league_object is not None:
#         statskey = info['key']
#         g = Game.all().filter('butterstats_key = ',statskey).get()
#         if not g:
#           self.response.out.write("creating game...\n")
#           g = Game()
#           g.butterstats_key = statskey
#         if g.starts_at and g.league:
#           old_period = get_base_period(g.starts_at,g.league)
#           old_key = key_for_number_of_games(g.starts_at,g.league)
#         else:
#           old_period = None
#           old_key = None
#         self.response.out.write('updating game...')
#         g.away_name = self.convert_to_picks_name(info['away_team']['name'])
#         g.home_name = self.convert_to_picks_name(info['home_team']['name'])
#         g.league = info['league']      
#         g.legit = info['legit']
#         g.away_score = info['away_score']
#         g.home_score = info['home_score']
#         g.status = info['status']
#         g.starts_at = datetime.fromtimestamp(info['starts_at'])        
#         g.last_updated_at = datetime.fromtimestamp(info['updated_at'])
#         g.put()
        
#         new_period = get_base_period(g.starts_at,g.league)
#         new_period.all_updated = False
#         new_period.put()
#         new_period.delete_cache()
#         memcache.delete(key_for_number_of_games(g.starts_at,g.league))
#         if g.final() or g.postponed(): 
#           all_games_effectively_final = new_period.all_games_effectively_final()
#           if all_games_effectively_final:
#             period_keys_to_update[str(new_period.key())] = True
#           else:
#             period_keys_to_update[str(new_period.key())] = False
#           custom_periods = get_superset_custom_periods(new_period.league,new_period.starts_at(),new_period.ends_at())
#           for cp in custom_periods:
#             period_keys_to_update[str(cp.key())] = False #TODO 
#         if old_period:
#           old_period.delete_cache()
#           memcache.delete(old_key)
#     for k in period_keys_to_update:
#       params = {'period_key':k, 'all_games_effectively_final':period_keys_to_update[k]}
#       taskqueue.Task(method='GET',url='/update_participant_periods',params=params).add('updatepp')      
