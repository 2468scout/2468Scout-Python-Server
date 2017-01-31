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
#bundle install

ENV['SSL_CERT_FILE'] = 'human/cacert.pem'

set :bind, '0.0.0.0' #localhost
set :port, 8080   #DO NOT CHANGE without coordination w/client
enable :lock #One request processed at a time

Dir.mkdir 'public' unless File.exists? 'public' #Sinatra will be weird otherwise

#Data is to be gitignored. The server will have to create a folder for itself.
#Alternatively, gitignore the entire public directory- works much better. (Also gitignores all of these subdirectories)

Dir.mkdir 'public/Matches' unless File.exists? 'public/Matches'
Dir.mkdir 'public/Teams' unless File.exists? 'public/Teams'
Dir.mkdir 'public/TeamMatches' unless File.exists? 'public/TeamMatches'
Dir.mkdir 'public/Events' unless File.exists? 'public/Events' 
Dir.mkdir 'apidata' unless File.exists? 'apidata'

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('human/apitoken.txt').read #Auth token from installation
$requests = {} #Requests from our server to the API
$events = {} #All events this season, from API

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def api(path) #Returns the FRC API file for the specified path in JSON format.
  begin
  	puts "I am accessing the API at path #{path}"
    open("#{$server}#{path}", #https://frc-api. ... .org/v.2.0/ ... /the thing we want
      'User-Agent' => "https://github.com/2468scout/2468Scout-Ruby-Server", #Dunno what this is but Isaac did it
      'Authorization' => "Basic #{$token}", #Standard procedure outlined by their API
      'accept' => "application/json" #We want JSON files, so we will ask for JSON
    ).read
  rescue => e
  	puts "Something went wrong #{e.class}, message is #{e.message}"
    return '{}' #If error, return empty JSON-ish.
  end
end

def reqapi(path) #Make sure we don't ask for the same thing too often
  begin
      req = path
      if $requests[req] && ($requests[req][:time] + 120 > Time.now.to_f) 
        $requests[req][:data] #we requested the same thing within 2 minutes
      else
        $requests[req] = {
            data: api(req),
            time: Time.now.to_f
          }
          $requests[req][:data] #new request so we make a new one and return its data
      end
    rescue
      # status 404
      puts("Status 404")
      return '{}'
    end
end

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
puts($frcEvents.empty?)

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

### GET REQUESTS

get '/getEvents' do # Return a JSON of the events we got directly from the API, as well as an identifier
  content_type :json
  $events
end

get '/getSimpleTeamList' do
  tempeventcode = params['eventCode']
  content_type :json
  getSimpleTeamList(tempeventcode)
end

get '/getMatchList' do
  content_type :json
  '{"test":"Success"}'
end

get '/getTeamMatch' do #Return a JSON of match data for a particular team?? (idk.. Ian vult)
  begin
    content_type :json
    eventcode = params['eventCode']
    teamnumber = params['teamNumber']
    matchnumber = params['matchNumber']
    filename = "public/data/"+eventcode+"_Match"+matchnumber.to_s+"_Team"+teamnumber.to_s+".json"
    retrieveJSON(filename)
  rescue => e
    puts e
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

### POST REQUESTS

post '/postpit' do # Pit scouting (receive team data) #input is an actual string
  begin
    # Congration u done it
    testvar = params['test']
    puts testvar
    status 200
  rescue => e
    puts e
    status 400
  end
end

post '/postTeamMatch' do # eventcode, teamnuber, matchnumber, all matchevents
  begin
    saveTeamMatchInfo(params['obj'])
    # EXPERIMENTAL: saveMatchInfo(??) for simulations
    status 200
  rescue => e
    puts "SOILED IT #{e.class}, message is #{e.message}"
    puts e.message
    status 400
  end
end

post '/postTeamImage' do
  begin
    teamnum = params['iTeamNumber']
    eventcode = params['sEventCode']
    # HOW DO I HANDLE IMAGES
    status 200
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