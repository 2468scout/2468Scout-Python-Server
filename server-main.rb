#set SSL_CERT_FILE=D:/ScoutAppServer/2468Scout-Python-Server/human/cacert.pem

################################################
################TABLE OF CONTENTS###############
################################################
# Initialization
# Class Definition
# Request Handling
# Number Crunching
# Analytics


################################################
##############BEGIN INITIALIZATION##############
################################################

#Gems the server needs
require 'sinatra' #Web server
require 'json'    #Send & receive JSON data
require 'open-uri'#Wrapper for Net::HTTP (interact with FRC API and client)
require 'uri'     #Uniform Resource Identifiers (interact with FRC API and client)
require 'openssl' #Not sure if we need this but we've been having some SSL awkwardness

set :bind, '0.0.0.0' #localhost
set :port, 8080   #DO NOT CHANGE without coordination w/client

Dir.mkdir 'public' unless File.exists? 'public' #Sinatra will be weird otherwise
Dir.mkdir 'public/data' unless File.exists? 'public/data' #Data is to be gitignored. The server will have to create a folder for itself.

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('human/apitoken.txt').read #Auth token from installation

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def api(path) #Returns the FRC API file for the specified path in JSON format.
  begin
  	puts "I am accessing the API at path #{path}"
    open("#{$server}#{path}", #https://frc-api. ... .org/v.2.0/ ... /the thing we want
      "User-Agent" => "https://github.com/2468scout/2468Scout-Ruby-Server", #Dunno what this is but Isaac did it
      "Authorization" => "Basic #{$token}", #Standard procedure outlined by their API
      "accept" => "application/json" #We want JSON files, so we will ask for JSON
    ).read
  rescue => e
  	puts "Something went wrong #{e.class}, message is #{e.message}"
    return '{}' #If error, return empty JSON-ish.
  end
end

$events = api('events/') #Get all the events from the API so we don't have to keep bothering them

#OPTIONAL PROJECT FOR LATER:
#use eventcodes matrix to verify that a user-submitted event code is valid
#$eventcodes = []
#$events.each do |event|
#	$eventcodes << event['code']
#end


################################################
#############BEGIN CLASS DEFINITION#############
################################################

Class FRCEvent #one for each event
	@sEventName = '' #the long name of the event
	@sEventCode = '' #the event code
	@teamNameList = [] #array of all teams attending
	@teamMatchList = [] #array of all TeamMatch objects, 6 per match
	@matchList = [] #array of all Match objects containing score, rp, some sht
	def initialize(eventName, eventCode, tNameList, tMatchList, mList, namesByMatchList)
		@sEventName = eventName
		@sEventCode = eventCode
		@teamNameList = tNameList
		@teamMatchList = tMatchList
		@matchList = mList
		@listNamesByTeamMatch = namesByMatchList
  end
end

Class Match #one for each match in an event
	@iMatchNumber = -1 #match ID
	@iRedScore = -1 #points earned by red (from API)
	@iBlueScore = -1 #points earned by blue (from API)
	@iRedRankingPoints = -1 #ranking points earned by red (from API)
	@iBlueRankingPoints = -1 #ranking points earned by blue (from API)
	@sCompetitionLevel = '' #the event.. level??? ffs thats a different api call entirely
	@sEventCode = '' #the event code
	@teamMatchList = [] #array of 6 TeamMatch objects
	def initialize(matchNum, redMP, blueMP, redRP, blueRP, complevel, eventCode, tMatchList)
		@iMatchNumber = matchNum
		@iRedScore = redMP
		@iBlueScore = blueMP
		@iRedRankingPoints = redRP
		@iBlueRankingPoints = blueRP
		@sCompetitionLevel = complevel
		@sEventCode = eventCode
		@teamMatchList = tMatchList
	end
end

Class Team #one for each team .. ever
	@sTeamName = ''
	@iTeamNumber = -1
	@awardsList = []
	@avgGearsPerMatch = -1
	@avgHighFuelPerMatch = -1
	@avgLowFuelPerMatch = -1
	@avgRankingPoints = -1
	def initialize(teamName, teamNum, awardsArray, gearspermatch, highpermatch, lowpermatch, avgrp)
		@sTeamName = teamName
		@iTeamNumber = teamNum
		@awardsList = awardsArray
		@avgGearsPerMatch = gearspermatch
		@avgHighFuelPerMatch = highpermatch
		@avgLowFuelPerMatch = lowpermatch
		@avgRankingPoints = avgrp
	end
end

Class MatchEvent #many per match
	@iTimeStamp = -1 #how much time
	@iPointValue = -1 #how many point earned
	@iCount = -1 #how many time
	@bInAutonomous #happened in autonomous yes/no
	@sEventName #wtf why do we need an event name for every single piece of a match
	@loc #Point object
	def initialize(timStamp, pointVal, cnt, isauto, eventname, location)
		@iTimeStamp = timStamp
		@iPointValue = pointVal
		@iCount = cnt
		@bInAutonomous = isauto
		@sEventName = eventName
		@loc = location
	end
end

Class Point
	@x = 0
	@y = 0
	def initialize(myx, myy)
		@x = myx
		@y = myy
	end
end

Class SimpleTeam
	@sTeamName = ''
	@iTeamNumber = -1
	def intialize(teamname, teamnumber)
		@sTeamName = teamName
		@iTeamNumber = teamnumber
	end
end


################################################
#############BEGIN REQUEST HANDLING#############
################################################
#GET - Client requests data from a specified resource
#POST - Client submits data to be processed to a specified resource

###GET REQUESTS

get '/getevents' do #Return a JSON of the events we got directly from the API, as well as an identifier
	content_type :json
 	$events
end

get '/getteamlist' do
	output = []
	tempeventcode = params[:eventcode]
	tempjson = JSON.parse(api('teams?eventCode=' + tempeventcode))
	
	tempjson['teams'].each do |team|
		output << {iTeamNumber: team['teamNumber'].to_i, sTeamName: team['nameShort']}.to_h
	end	
	content_type :json
	output.to_json
end

get '/getmatchlist' do
	content_type :json
	'{"test":"Success"}'
end

get '/getteammatch' do #Return a JSON of match data for a particular team?? (idk.. Ian vult)
	puts "I got a get request"
	content_type :json
	'{"test":"Success"}'
end

###POST REQUESTS

post '/postpit' do #Pit scouting (receive team data) #input is an actual string
	begin
  		#Congration u done it
  		testvar = params['test']
  		puts testvar
    	status 200
	rescue => e
    	puts e
    	status 400
	end
end

post '/postteammatch' do #Team scouting (recieve team and match data) #input is an actual string
	begin
		testvar = params['test']
  		puts testvar
  		#saveTeamMatchInfo(eventcode,matchnumber,teamnumber,jsondata)
  		#EXPERIMENTAL: saveMatchInfo(??) for simulations
		status 200
	rescue => e
		puts e
		status 400
	end
end


################################################
#############BEGIN NUMBER CRUNCHING#############
################################################

##Helpful stuff##
#params['param']
#JSON.parse
#to_json
#File.open('public/data/_____','r' or 'w')
#File.close

def retrieveJSON(filename) #return JSON of a file to make it available for rewrite
	txtfile = File.open(filename,'r')
	content = ''
	txtfile.each do |line|
		content << line
	end
	txtfile.close
	JSON.parse(content)
end

def saveTeamMatchInfo(eventcode="", matchnumber=0,teamnumber=0,jsondata='{}')
	jsondata = JSON.parse(jsondata)
	filename = "public/data/"+eventcode+"_Match"+matchnumber.to_s+"_Team"+teamnumber.to_s+".json"
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata #array of all MatchEvent objects into file. maybe?
	jsonfile.close
	#Possible extra task: compare existing json to saved json in case of double-saving
	puts "Successfully saved " + filename
end

def saveTeamPitInfo(jsondata)
	jsondata = JSON.parse(jsondata)
	filename = "public/data/"+eventcode+"_Pit_Team"+teamnumber.to_s+".json"
	existingjson = '{}'
	#if File.exists? filename
	#	existingjson = retrieveJSON(filename)
	#end
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata
	jsonfile.close
	puts "Successfully saved " + filename
end


################################################
################BEGIN ANALYTICS#################
################################################

def analyzeTeamMatchInfo(matcheventname)
	#JSON.parse
	#.each do ||
	#an array for each? sad boi
end

#Match scouting (send list of matches, alliances, teams)
#Match scouting (receive match scout data)
#Analytics home (send relevant statistics)
#Analytics specific (send specific statistics)
#Team profile (send statistics for a given team, AS WELL AS relevant matches)