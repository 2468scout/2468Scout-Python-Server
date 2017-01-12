#set SSL_CERT_FILE=D:/ScoutAppServer/2468Scout-Python-Server/cacert.pem

#Gems the server needs
require 'sinatra' #Web server
require 'json'    #Send & receive JSON data
require 'open-uri'#Wrapper for Net::HTTP (interact with FRC API and client)
require 'uri'     #Uniform Resource Identifiers (interact with FRC API and client)
require 'openssl' #Not sure if we need this but we've been having some SSL awkwardness

#Initialization stuff - shamelessly ripped from Isaac
set :bind, '0.0.0.0'
set :port, 8080   #DO NOT CHANGE without coordination w/client

Dir.mkdir 'public' unless File.exists? 'public' #Sinatra will be weird otherwise
Dir.mkdir 'public/data' unless File.exists? 'public/data' #Data is to be gitignored. The server will have to create a folder for itself.

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('apitoken.txt').read #Auth token from installation

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def api(path) #Returns the FRC API file for the specified path in JSON format.
  begin
  	puts "I am accessing the API"
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

$events = api('events/') #Get a list of events (competitions regionals etc) from FRC API #Actually I'm not sure
$registrations = api('registrations') #"Registrations":[{"teamNumber":#,"Events":[EVENT CODES]}],"count":1

#OPTIONAL PROJECT FOR LATER:
#use eventcodes matrix to verify that a user-submitted event code is valid
#$eventcodes = []
#$events.each do |event|
#	$eventcodes << event['code']
#end


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

get '/getmatchlist:name' do #:name - event name parameter, Return all matches under event of :name
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
	filename = eventcode+"_Match"+matchnumber+"_Team"+teamnumber+".json"
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata
	#array of all MatchEvent objects into file
	jsonfile.close

	#Possible extra task: compare existing json to saved json in case of double-saving
end

def saveTeamPitInfo()
	jsondata = JSON.parse(jsondata)
	filename = eventcode+"_Pit_Team"+teamnumber+".json"
	existingjson = '{}'
	if File.exists? filename
		existingjson = retrieveJSON(filename)
	end
	jsonfile = File.open(filename,'w')
	#compare jsondata to existingjson
	#and merge whatever is whatever
	jsonfile.close
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