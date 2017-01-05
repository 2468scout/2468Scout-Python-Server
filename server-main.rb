#Gems the server needs
require 'sinatra' #Web server
require 'json'    #Send & receive JSON data
require 'open-uri'#Wrapper for Net::HTTP (interact with FRC API and client)
require 'uri'     #Uniform Resource Identifiers (interact with FRC API)

#Initialization stuff - shamelessly ripped from Isaac
set :bind, '0.0.0.0'
set :port, 8080   #DO NOT CHANGE without coordination w/client

Dir.mkdir 'public/data' unless File.exists? 'public/data' #Data is to be gitignored. The server will have to create a folder for itself.

$server = 'https://frc-api.firstinspires.org/v2.0/'+Time.now.year.to_s+'/' #Provides matches, events for us.. put -staging after "frc" for practice matches
$token = open('apitoken').read #Auth token from installation

def api(path) #Returns the FRC API file for the specified path in JSON format.
  begin
    open("#{$server}#{path}", #https://frc-api. ... .org/v.2.0/ ... /the thing we want
      #"User-Agent" => "https://github.com/2468scout/2468Scout-Ruby-Server", #Dunno what this is but Isaac did it
      "Authorization" => "Basic #{$token}", #Standard procedure outlined by their API
      "accept" => "application/json" #We want JSON files, so we will ask for JSON
    ).read
  rescue
    return '{}' #If error, return empty JSON-like.
  end
end

$events = api('events/') #Get a list of events (competitions regionals etc) from FRC API

################################################
#############BEGIN REQUEST HANDLING#############
################################################
#GET - Client requests data from a specified resource
#POST - Client submits data to be processed to a specified resource

get '/events' do #Pass a JSON of the events we got directly from the API, as well as an identifier
  content_type :json
  $events
end

post '/pit' do #Pit scouting (receive team data) #HANDLE A TXT FILE also GIVE THE STUFF NEEDED
  begin
  	#Congration u done it
    status 200
  rescue => e
    puts e
    status 400
  end
end



#Match scouting (send list of matches, alliances, teams)
#Match scouting (receive match scout data)
#Analytics home (send relevant statistics)
#Analytics specific (send specific statistics)
#Team profile (send statistics for a given team, AS WELL AS relevant matches)