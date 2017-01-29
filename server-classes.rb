

##################################################
############# BEGIN CLASS DEFINITION #############
##################################################

#FRCEvent will be sent to the client.
#TeamMatch will be received from the client.
#We should have a separate class, variable, or file for event analytical data to be easily accessed.

class Hashit
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
end

class FRCEvent #one for each event
	def initialize(eventName, eventCode)
		@sEventName = eventName #the long name of the event
		@sEventCode = eventCode #the event code
		@teamNameList = [] #array of all teams attending
		@teamMatchList = [] #array of all TeamMatch objects, 6 per match
		@matchList = [] #array of all Match objects containing match number,
	end
#	def initialize(hash)
#		hash.each do |key, value|
#			if value.is_a?(hash)
#				value = new Hashit(value)
#			end
#			self.instance_variable_set("@#{key}", value);
#		end
#	end
	attr_accessor :sEventName
    attr_accessor :sEventCode
    attr_accessor :teamNameList
    attr_accessor :teamMatchList
    attr_accessor :matchList
	def to_json
		{'sEventName' => @sEventName, 'sEventCode' => @sEventCode, 'teamNameList' => @teamNameList, 'teamMatchList' => @teamMatchList, 'matchList' => @matchList, 'listNamesByTeamMatch' => @listNamesByTeamMatch}
	end
end


def initializeFRCEventObject(jsondata)
	#jsondata = JSON.parse(jsondata)
	#FRCEvent.new(jsondata['sEventName'],)
end

class Match #one for each match in an event
	#Match contains all data for a match, including scores for analytics purposes.
	def initialize(matchNum, redMP, blueMP, redRP, blueRP, complevel, eventCode, tMatchList)
		@iMatchNumber = matchNum #match ID
		@iRedScore = redMP #points earned by red (from API)
		@iBlueScore = blueMP #points earned by blue (from API)
		@iRedRankingPoints = redRP #ranking points earned by red (from API)
		@iBlueRankingPoints = blueRP #ranking points earned by blue (from API)
		@sCompetitionLevel = complevel #the event.. level??? ffs thats a different api call entirely
		@sEventCode = eventCode #the event code
		@teamMatchList = tMatchList #array of 6 TeamMatch objects
	end
#	def initialize(hash)
#		hash.each do |key, value|
#			if value.is_a?(hash)
#				value = new Hashit(value)
#			end
#			self.instance_variable_set("@#{key}", value);
#		end
#	end
	def to_json
		{'iMatchNumber' => @iMatchNumber, 'iRedScore' => @iRedScore, 'iBlueScore' => @iBlueScore, 'iRedRankingPoints' => @iRedRankingPoints, 'iBlueRankingPoints' => @iBlueRankingPoints, 'sCompetitionLevel' => @sCompetitionLevel, 'sEventCode' => @sEventCode, 'teamMatchList' => @teamMatchList}
	end
    attr_accessor :iMatchNumber, :iRedScore, :iBlueScore, :iRedRankingPoints, :iBlueRankingPoints, :sCompetitionLevel, :sEventCode, :teamMatchList
end

class MatchData #one for each match in an event
	#MatchData contains data needed for scouting a match.
	def initialize(matchNum, complevel, eventCode, tMatchList)
		@iMatchNumber = matchNum #match ID
		@sCompetitionLevel = complevel #the event.. level??? ffs thats a different api call entirely
		@sEventCode = eventCode #the event code
		@teamMatchList = tMatchList #array of 6 TeamMatch objects
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json
		{'iMatchNumber' => @iMatchNumber, 'sCompetitionLevel' => @sCompetitionLevel, 'sEventCode' => @sEventCode, 'teamMatchList' => @teamMatchList}
	end
end


class Team #one for each team .. ever
	def initialize(teamName, teamNum, awardsArray, gearspermatch, highpermatch, lowpermatch, avgrp)
		@sTeamName = teamName
		@iTeamNumber = teamNum
		@awardsList = awardsArray
		@avgGearsPerMatch = gearspermatch
		@avgHighFuelPerMatch = highpermatch
		@avgLowFuelPerMatch = lowpermatch
		@avgRankingPoints = avgrp
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json
		{'sTeamName' => @sTeamName, 'iTeamNumber' => @iTeamNumber, 'awardsList' => @awardsList, 'avgGearsPerMatch' => @avgGearsPerMatch, 'avgHighFuelPerMatch' => @avgHighFuelPerMatch, 'avgLowFuelPerMatch' => @avgLowFuelPerMatch, 'avgRankingPoints' => @avgRankingPoints}.to_json
	end
end

class MatchEvent #many per TeamMatch
	def initialize(timStamp, pointVal, cnt, isauto, eventname, location)
		@iTimeStamp = timStamp #how much time
		@iPointValue = pointVal #how many point earned
		@iCount = cnt #how many time
		@bInAutonomous = isauto #happened in autonomous yes/no
		@sEventName = eventName #wtf why do we need an event name for every single piece of a match
		@loc = location #Point object
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json
		{'iTimeStamp' => @iTimeStamp, 'iPointValue' => @iPointValue, 'iCount' => @iCount, 'bInAutonomous' => @bInAutonomous, 'sEventName' => @sEventName, 'loc' => @loc}.to_json
	end
end

class Point
	def initialize(myx, myy)
		@x = myx
		@y = myy
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json
		{'x' => @x, 'y' => @y}.to_json
	end
end

class SimpleTeam
	def initialize(teamname, teamnumber)
		@sTeamName = teamname
		@iTeamNumber = teamnumber
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json
		{'sTeamName' => @sTeamName, 'iTeamNumber' => @iTeamNumber}.to_json
	end
end

class TeamMatch
	def initalize(teamNumber, matchNumber, numberInAlliance, allianceNumber, notes, eventCode, personScouting, color, listMatchEvents)
		@iTeamNumber = teamNumber
		@iMatchNumber = matchNumber
		@iStationNumber = numberInAlliance
		@iAllianceNumber = allianceNumber
		@sNotes = notes
		@sEventCode = eventCode
		@sPersonScouting = personScouting
		@bColor = color #Blue is True
		@matchEventList = listMatchEvents
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value);
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
end

################################################
#############BEGIN NUMBER CRUNCHING#############
################################################

#Filename format:
#Eventcode_Objecttype_Teamnum.json
#Objecttype: Pit, TeamMatch, Match
#Teamnum: The word "Team" followed by team number

def retrieveJSON(filename) #return JSON of a file
	txtfile = File.open(filename,'r')
	content = ''
	txtfile.each do |line|
		content << line
	end
	txtfile.close
	JSON.parse(content)
end
def saveEventsData (frcEvents)
	frcEvents.each do |event|
		filename = "public/Events/" + event.sEventCode + ".json"
        if(File.exists? filename)
            puts("Yeah, that file totally exists!")
            jsonfile = File.open(filename)
        else
            puts("File #{filename} does not exist")
            jsonfile = File.open(filename, 'w+')
        end
		jsonfile << event.to_json
		jsonfile.close
		puts "Successfully saved " + filename
	end
end

def saveTeamMatchInfo(jsondata)
	jsondata = JSON.parse(jsondata)
	eventcode = jsondata['sEventCode']
	teamnumber = jsondata['iTeamNumber']
	matchnumber = jsondata['iMatchNumber']
	filename = "public/TeamMatches/"+eventcode+"_TeamMatch"+matchnumber.to_s+"_Team"+teamnumber.to_s+".json"
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata #array of all MatchEvent objects into file. maybe?
	jsonfile.close
	#Possible extra task: compare existing json to saved json in case of double-saving
	puts "Successfully saved " + filename

	analyzeTeamAtEvent(teamnumber, eventcode)
end

def saveTeamPitInfo(jsondata)
	jsondata = JSON.parse(jsondata)
	eventcode = jsondata['sEventCode']
	teamnumber = jsondata['iTeamNumber']
	filename = "public/Teams/"+teamNumber.to_s+"/"+eventcode+"_Pit_Team"+teamnumber.to_s+".json"
	#existingjson = '{}'
	#if File.exists? filename
	#	existingjson = retrieveJSON(filename)
	#end
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata
	jsonfile.close
	puts "Successfully saved " + filename
end

def getSimpleTeamList(eventcode)
	output = []
	tempjson = JSON.parse(reqapi('teams?eventCode=' + eventcode))
	tempjson['teams'].each do |team|
		output << SimpleTeam.new(team['nameShort'].to_s,team['teamNumber'].to_i).to_json
	end	
	output.to_json
end

################################################
################BEGIN ANALYTICS#################
################################################

$rawscores = {}
#{CASJ: [], ABCA: [], etc, add as needed?}
#initialize from the event file?
#alternatively, have one global variable to control what event is preloaded (NOT RECOMMENDED)

def updateEventFromAPI(eventcode,lastmodified)
	#reqapi for all the latest data
	#first check if-modified-since (I do not know where to get lastmodified atm)
	#then overwrite all data, in case a correction was made, as it's all the same call anyway
	#finally, return a success/failure message
end

def updateScores(eventcode)
	#reqapi for the matches of an event
	#useful for winrates, scores, RP, rankings
end

def analyzeTeamAtEvent(teamnumber, eventcode)
	filenames = [] #Names of all relevant files
	pitfilenames = [] #Files for pit scouting
	teammatchfilenames = [] #Files for match scouting
	
	matchevents = []
	matchnums = []
	scores = []

	Dir.glob("public/Teams/"+teamNumber.to_s+"/"+eventcode+"_Pit_Team"+teamnumber.to_s+".json") do |filename|
		filenames << filename
		pitfilenames << filename
	end
	Dir.glob("public/TeamMatches/"+eventcode+"_TeamMatch*_Team"+teamnumber.to_s+".json") do |filename|
		filenames << filename
		teammatchfilenames << filename
	end
	if filenames.size #If the number of relevant files is not 0
		#combine similar json objects into arrays
		if pitfilenames.size #If there are pit files
			pitfilenames.each do |filename| #Go through the files
				tempjson = retrieveJSON(filename) #Convert them to json
				#combine pit stuff (client-dependent)
				#until we know what is being scouted from the pit, ignore this for now
			end #end pitfilenames foreach
		end #end if pitfilenames.size
		if teammatchfilenames.size #If there are match files
			teammatchfilenames.each do |filename| #Go through the files
				tempjson = retrieveJSON(filename) #Convert them to json
				if tempjson['matchEvents'] #If this json has a list of match events
					tempjson['matchEvents'].each do |matchevent| #Go through the match events
						matchevents << matchevent #Add the matchevents to an array of team's match events
					end #end matchevents foreach
				end #end if tempjson['mathEvents']
				if tempjson['iMatchNumber'] #If this json has a match number
					matchnums << tempjson['iMatchNumber'] #Add the matchnumber to an array of team's matchnums
				end #end if tempjson['iMatchNumber']
			end #end teammatchfilenames foreach
		end #end if teammatchfilenames.size
	end #end if filenames.size

	sortedevents = sortMatchEvents(matchevents)
	#Call the specific methods

	puts filenames.size.to_s + ' files found'
	
	#API Call goes here

	{"filesFound" => filenames}.to_json
	#{'matchEvents' => matchevents}.to_json
end

def analyzeTeamInMatch(teamnum, matchnum, eventname)
	#specific match-by-match, instead of hollistic
end

def sortMatchEvents(matchevents = [])
	#receive an array of match events
	#return an array of arrays of match events
	#sort using sMatchEventName
	sortedevents = [[],[]]
	sortedevents
	#sortedevents[0] : highFuelStart, highFuelStop matchevents
	#etc
end

def analyzeHighGoals(highfuelevents = [])
	#receive an array of relevant match events
	#return an array of analytics
	analyzed = [[],[]]
	analyzed
	#analyzed[0] : attempted per teleop
	#analyzed[1] : accuracy per teleop
	#analyzed[2] : attempted per autonomous
	#analyzed[3] : accuracy in autonomous
	#analyzed[4] : score earned per match from high goals
end
