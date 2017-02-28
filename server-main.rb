#set SSL_CERT_FILE=D:/ScoutAppServer/2468Scout-Python-Server/human/cacert.pem

################################################
##############BEGIN INITIALIZATION##############
################################################

#Gems (imports) the server needs
require 'rubygems'#All of the gems in one, supposedly :thinking:
require 'sinatra' #Web server
require 'json'    #Send & receive JSON data
require 'open-uri'#Wrapper for Net::HTTP (interact with FRC API and client)
require 'uri'     #Uniform Resource Identifiers (interact with FRC API and client)
require 'openssl' #Not sure if we need this but we've been having some SSL awkwardness
require 'ostruct' #Turn JSON into instant objects! Huzzah!
require_relative 'server-classes.rb'
require_relative 'server-analysis.rb'
require_relative 'server-utility.rb'
#bundle install

ENV['SSL_CERT_FILE'] = 'human/cacert.pem'

set :bind, '0.0.0.0' #'http://scouting.westaaustin.org/' #localhost
set :port, 8080   #DO NOT CHANGE without coordination w/client
enable :lock #One request processed at a time

Dir.mkdir 'public' unless File.exists? 'public' #Sinatra will be weird otherwise

#Data is to be gitignored. The server will have to create a folder for itself.
#Alternatively, gitignore the entire public directory- works much better. (Also gitignores all of these subdirectories)

Dir.mkdir 'public/Matches' unless File.exists? 'public/Matches'
Dir.mkdir 'public/Teams' unless File.exists? 'public/Teams'
Dir.mkdir 'public/TeamMatches' unless File.exists? 'public/TeamMatches'
Dir.mkdir 'public/Events' unless File.exists? 'public/Events' 
Dir.mkdir 'public/Scores' unless File.exists? 'public/Scores'
Dir.mkdir 'apidata' unless File.exists? 'apidata'

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('human/apitoken.txt').read #Auth token from installation
$requests = {} #Requests from our server to the API
$events = {} #All events this season, from API

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#$cache = {} #Stuff that the clients are asking us for

def api(path,lastmodified = nil) #Returns the FRC API file for the specified path in JSON format.
  #Warning: api() returns an HTTP response while reqapi() returns a JSON string.
  begin
  	puts "I am accessing the API at path #{path}"
  	options = {  'User-Agent' => "https://github.com/2468scout/2468Scout-Ruby-Server", #Dunno what this is but Isaac did it
      'Authorization' => "Basic #{$token}", #Standard procedure outlined by their API
      'accept' => "application/json" #We want JSON files, so we will ask for JSON
 	}
 	#FMS-OnlyModifiedSince will return just a 304
 	#If-Modified-Since will return a 200 no matter what, for some reason
  	options['FMS-OnlyModifiedSince'] = lastmodified if lastmodified
    #puts options['If-Modified-Since']
    #open("#{$server}#{path}", options).read
    toreturn = {}
    open("#{$server}#{path}", options) do |response|
    	body = ""
    	response.each_line do |line|
    		body << line.to_s
    	end
    	#response.base_uri.to_s
    	toreturn = OpenStruct.new(:body => body, :meta => response.meta, :status => response.status)
    	#must create a persistent object out of the response, as response is not accessible outside this method
    end
    toreturn
  rescue => e
  	puts "Something went wrong #{e.class}, message is #{e.message}"
    toreturn = '{}'
    if (e.message.include? '304') 
    	toreturn = OpenStruct.new(:body => '{}', :status => ['304','Not Modified'])
	end
	toreturn #If error, return empty JSON-ish, or 304 if 304
  end
end


def reqapi(path, override = false) #Make sure we don't ask for the same thing too often
  #Returns a string equivalent to the body of the request
  begin
      req = path
      if $requests[req] && ($requests[req][:time] + 90 > Time.now.to_f) && !override
        #$requests[req][:data] 
        #We requested the same thing within 2 minutes
      	puts "Old request (within 90 seconds)! Use lastmodified"
      	myrequest = api(req, $requests[req][:lastmodified])
      elsif $requests[req] && ($requests[req][:time] + 5 > Time.now.to_f) && override
      	puts "Overridden request (within 5 seconds)! Use lastmodified"
      	myrequest = api(req, $request[req][:lastmodified])
      else	
      	puts "New or overridden request! Ignore lastmodified"
      	myrequest = api(req)
      end

      puts "My request's code is #{myrequest.status}"

      unless myrequest.status[0].to_s === '304'
      	puts "it has been modified"
        $requests[req] = { #new request so create new request
            data: myrequest,
            time: Time.now.to_f,
            lastmodified: myrequest.meta["last-modified"]
          }
      end
      $requests[req][:data].body #return data to the method caller
    rescue => e
      # status 404
      puts "Reqapi messed up #{e.message}"
      return '{}'
    end
end

#Ian's code
#You can tell because there are no comments LMAO

puts("Begin events initialization")
eventsString = reqapi('events/')
#puts("Results from FRCAPI events list: " + eventsString)
$events = JSON.parse(eventsString) #Get all the events from the API so we don't have to keep bothering them
$frcEvents = []
$events["Events"].each do |event|
  if(event['code'] == "CMPTX" || event['code'] == "CASJ" || event['code'] == "TXDA" || event['code'] == "TXLU" )
    tempEvent = FRCEvent.new(event['name'], event['code'])
    $frcEvents << tempEvent
  end
end
puts("Is frcEvents empty? #{$frcEvents.empty?}")

$frcEvents.each do |frcevent|
  receivedEvent = {}
  receivedEvent = JSON.parse(reqapi('schedule/' + frcevent.sEventCode + '?tournamentLevel=qual'))
  frcevent.matchList = []
  unless receivedEvent.empty?
    receivedEvent['Schedule'].each do |match|
      tempMatch = Match.new(match['matchNumber'], nil, nil, nil, nil, "qual", nil)
      tempMatch.teamMatchList = []
      match['Teams'].each do |team|
        tempMatch.teamMatchList << TeamMatch.new(team['number'], match['matchNumber'], 
        /\d+/.match(team['station']).try(:[], 0), # I have literally no idea what this does, but it should work lol
        nil, nil, frcevent.sEventCode, nil, team['station'][0] == "B", nil)
      end
      frcevent.matchList << tempMatch
    end
  end
end
$frcEvents.each do |frcevent|
  frcevent.simpleTeamList = []
  receivedTeamList = {}
  receivedTeamList = JSON.parse(reqapi('teams?eventCode=' + frcevent.sEventCode))
  if !receivedTeamList.empty?
    receivedTeamList['teams'].each do |receivedTeam|
      frcevent.simpleTeamList << SimpleTeam.new(receivedTeam['nameShort'],receivedTeam["teamNumber"])
    end
  end
end

saveEventsData($frcEvents)

# Need to find the following specific events: CMPTX, CASJ, TXDA, TXLU

##################################################
############# BEGIN REQUEST HANDLING #############
##################################################
# GET - Client requests data from a specified resource
# POST - Client submits data to be processed to a specified resource
#See documentation for details on the requests below

### GET REQUESTS

get '/' do
	return "What are you doing here? This is not a website."
end

get '/getEvents' do # Return a JSON of the events we got directly from the API, as well as an identifier
  content_type :json
  $events
end

get '/getSimpleTeamList' do
  tempeventcode = params['eventCode']
  content_type :json
  getSimpleTeamList(tempeventcode)
end

get '/getMatchScores' do #Return a JSON of scores for easy schedule viewing
  tempeventcode = params['eventCode']
  output = {"playoffs": [], "qualifiers": []}
  matchresults = getScores(tempeventcode)
  matchresults.each do |matchresult|
  	thismatch = {
  		"iMatchNumber": matchresult['matchNumber'],
  		"iScoreRed": matchresult['scoreRedFinal'],
  		"iScoreBlue": matchresult['scoreBlueFinal'],
  		"bBlueWin": (matchresult['scoreBlueFinal'].to_i > matchresult['scoreRedFinal'].to_i),
  		"teams": matchresult['teams']
  	}
  	#thismatch = Match.new(matchresult['matchNumber'], matchresult['scoreRedFinal'], matchresult['scoreBlueFinal'], -1, -1, matchresult['tournamentLevel'], tempeventcode, [])
    if matchresult["tournamentlevel"].eql? "Qualification"
    	output['playoffs'] << thismatch
    elsif matchresult["tournamentlevel"].eql? "Playoff"
    	output['qualifiers'] << thismatch
	else    
    	puts "Error: I have no idea where to put this #{matchsult['tournamentlevel']}"
    end
  end
  content_type :json
  output.to_json
end

get '/getTeamMatch' do #Return a JSON of match data for a particular team?? (idk.. Ian vult)
  begin
    content_type :json
    eventcode = params['eventCode']
    teamnumber = params['teamNumber']
    matchnumber = params['matchNumber']
    filename = "public/TeamMatches/"+eventcode+"_Match"+matchnumber.to_s+"_Team"+teamnumber.to_s+".json"
    retrieveJSON(filename)
  rescue => e
    puts "Error in getteammatch #{e.class}, message is #{e.message}"
    status 400
    return '{}'
  end
end

get '/getTeamAnalytics' do
  teamnumber = params['teamNumber']
  eventcode = params['eventCode']
  puts "Analyzing team #{teamnumber} at event #{eventcode}"
  content_type :json
  analyzeTeamAtEvent(teamnumber, eventcode)
end

get '/getTeamMatchExistence' do #Check if a teammatch exists in the server's database, to confirm saving/deletion
	eventcode = params['eventCode']
    teamnumber = params['teamNumber']
    matchnumber = params['matchNumber']
    filename = "public/TeamMatches/"+eventcode+"_Match"+matchnumber.to_s+"_Team"+teamnumber.to_s+".json"
    if File.exists? filename
		  return 'true' #We have the data
    else
    	return 'false' #We do not have the data
    end
end

get '/getFileExistence' do
	filename = request.env["FILEPATH"]
	if File.exists?filename
		return 'true'
	else
		return 'false'
	end
end

get '/getMatchTable' do
	eventcode = params['eventCode']
    matchnumber = params['matchNumber']
    output = matchTable(eventcode, matchnumber)
    content_type :json
    output
end

### POST REQUESTS

post '/postPit' do
  begin
    #Save info
    saveTeamPitInfo(request.body.string)

    #Rolling analysis later
    #jsondata = JSON.parse(request.body.string)
	  #eventcode = jsondata['sEventCode']
	  #teamnumber = jsondata['iTeamNumber']
	  #analyzeTeamPit(teamnumber, eventcode)

    status 200
  rescue => e
    puts e
    status 400
  end
end

post '/postTeamMatch' do
  begin
  	#Save team info
    saveTeamMatchInfo(request.body.string)
 	puts "I did it"
    #Rolling analysis
    #jsondata = JSON.parse(request.body)
	#  eventcode = jsondata['sEventCode']
	#  teamnumber = jsondata['iTeamNumber']

    status 200
  rescue => e
    puts "Error in postteammatch #{e.class}, message is #{e.message}"
    status 400
  end
end

post '/postMatchScores' do
	begin
		#Real-time scorekeeping
		saveScoreScoutInfo(request.body.string)
		
		status 200
	rescue => e
		puts "Error in postmatchscores #{e.class}, message is #{e.message}"
		status 400
	end
end

post '/postTeamImage' do
  begin
    #teamnum = params['iTeamNumber']
    #eventcode = params['sEventCode']
    # HOW DO I HANDLE IMAGES
    status 200
  rescue
    status 400
  end
end

post '/updateScores' do #Force update match scores
	begin
		eventcode = params['eventCode']
		updateScores(eventcode)
		status 200
	rescue
		status 400
	end
end

post '/updateEventData' do
	#Include a param to override reqapi and just call api directly
	begin
		eventcode = params['eventCode']
		updateScores(eventcode)
		updateRanks(eventcode)
		status 200
	rescue
		status 400
	end
end

post '/setupScoutSchedule' do
	begin
		eventcode = params['eventCode']
		puts "I am ready to make scout schedule at #{eventcode}"
		saveCalculateScoutSchedule(request.body.string, eventcode)
		status 200
	rescue
		status 400
	end
end

post '/addScoutScheduleRematch' do
	begin
		eventcode = params['eventCode']
		matchnumber = params['matchNumber']
		addRematchToScoutSchedule(eventcode, matchnumber)
		status 200
	rescue
		status 400
	end
end

post '/makePreMatch' do
	begin
		eventcode = params['eventCode']
		matchnumber = params['matchNumber']
		prematch = upcomingMatchSummary(eventcode, matchnumber)
		content_type :json
		status 200
		body prematch.to_json
	rescue
		status 400
	end
end

# dummy inputs for testing
# saveTeamPitInfo({'sEventCode' => 'TXDA', 'iTeamNumber' => 2468, 'data' => 'This is a broken robot!'}.to_json)
# saveTeamMatchInfo({'sEventCode' => 'TXSA', 'iTeamNumber' => 2468, 'iMatchNumber' => 10, 'data' => 'This team scored low!'}.to_json)
# saveTeamMatchInfo({'sEventCode' => 'CASJ', 'iTeamNumber' => 2468, 'iMatchNumber' => 3, 'data' => 'This team scored high!'}.to_json)
# saveTeamMatchInfo({'sEventCode' => 'CASJ', 'iTeamNumber' => 2468, 'iMatchNumber' => 40, 'data' => 'This team broke down!'}.to_json)
# saveTeamPitInfo({'sEventCode' => 'CASJ', 'iTeamNumber' => 2468, 'data' => 'This is a cool robot!'}.to_json)
# analyzeTeamAtEvent(2468,'CASJ')
# 5 files, 3 relevant