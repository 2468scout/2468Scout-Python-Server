#Gems the server needs
require 'sinatra' #Web server
require 'json'    #Send & receive JSON data
require 'open-uri'#Wrapper for Net::HTTP (interact with FRC API and client)
require 'uri'     #Uniform Resource Identifiers (interact with FRC API and client)

#Initialization stuff - shamelessly ripped from Isaac
set :bind, '0.0.0.0'
set :port, 8080   #DO NOT CHANGE without coordination w/client

Dir.mkdir 'public/data' unless File.exists? 'public/data' #Data is to be gitignored. The server will have to create a folder for itself.

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('apitoken.txt').read #Auth token from installation

def api(path) #Returns the FRC API file for the specified path in JSON format.
  begin
    open("#{$server}#{path}", #https://frc-api. ... .org/v.2.0/ ... /the thing we want
      #"User-Agent" => "https://github.com/2468scout/2468Scout-Ruby-Server", #Dunno what this is but Isaac did it
      "Authorization" => "Basic #{$token}", #Standard procedure outlined by their API
      "accept" => "application/json" #We want JSON files, so we will ask for JSON
    ).read
  rescue
    return '{}' #If error, return empty JSON-ish.
  end
end

$events = api('events/') #Get a list of events (competitions regionals etc) from FRC API


################################################
#############BEGIN REQUEST HANDLING#############
################################################
#GET - Client requests data from a specified resource
#POST - Client submits data to be processed to a specified resource

###GET REQUESTS

get '/events' do #Return a JSON of the events we got directly from the API, as well as an identifier
	content_type :json
 	$events
end

get '/getmatchlist:name' do #:name - event name parameter, Return all matches under event of :name
	content_type :json
	'{"test":"here is the matches"}'
end

get '/getteammatch' do #Return a JSON of match data for a particular team?? (idk.. Ian vult)
	content_type :json
	'{"test":"here is a team match"}'
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

def saveTeamMatchInfo(matchnumber=0,teamnumber=0)
	File.open("Data_Match"+matchnumber+"_Team"+matchnumber,'w')
end

def saveTeamInfo()

end


################################################
################BEGIN ANALYTICS#################
################################################


#Match scouting (send list of matches, alliances, teams)
#Match scouting (receive match scout data)
#Analytics home (send relevant statistics)
#Analytics specific (send specific statistics)
#Team profile (send statistics for a given team, AS WELL AS relevant matches)