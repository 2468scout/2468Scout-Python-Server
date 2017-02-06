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
      instance_variable_set("@#{key}", value)
    end
  end
end

class ScheduleItem
  def initialize(personResponsible, itemType, eventCode, matchNumber, teamNumber)
    @sPersonResponsible = personResponsible
    @sItemType = itemType
    @sEventCode = eventCode
    @iMatchNumber = matchNumber
    @iTeamNumber = teamNumber
  end
end

class ScoreScout
  def initialize()
  end
end

class FRCEvent #one for each event  
  def initialize(eventName, eventCode)
    @sEventName = eventName #the long name of the event
    @sEventCode = eventCode #the event code
    @simpleTeamList = [] #array of all teams attending
    @scheduleItemList = []
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
  attr_accessor :simpleTeamList
  attr_accessor :teamMatchList
  attr_accessor :matchList
  def to_json(options)
    # JSON.pretty_generate(self, options)
    {:sEventName => @sEventName, :sEventCode => @sEventCode, :simpleTeamList => @simpleTeamList, :teamMatchList => @teamMatchList, :matchList => @matchList}.to_json(options)
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
	def to_json(options)
    # JSON.pretty_generate(self, options)
		{':iMatchNumber' => @iMatchNumber, ':iRedScore' => @iRedScore, ':iBlueScore' => @iBlueScore, ':iRedRankingPoints' => @iRedRankingPoints, ':iBlueRankingPoints' => @iBlueRankingPoints, ':sCompetitionLevel' => @sCompetitionLevel, ':sEventCode' => @sEventCode, ':teamMatchList' => @teamMatchList}.to_json(options)
	end
    attr_accessor :iMatchNumber, :iRedScore, :iBlueScore, :iRedRankingPoints, :iBlueRankingPoints, :sCompetitionLevel, :sEventCode, :teamMatchList
end

class SimpleMatch #one for each match in an event
	#MatchData contains data needed for scouting a match.
	def initialize(matchNum, complevel, eventCode)
		@iMatchNumber = matchNum #match ID
		@sCompetitionLevel = complevel #the event.. level??? ffs thats a different api call entirely
		@sEventCode = eventCode #the event code
	end
	def initialize(hash)
		hash.each do |key, value|
			if value.is_a?(hash)
				value = new Hashit(value)
			end
			self.instance_variable_set("@#{key}", value);
		end
	end
	def to_json(options)
    # JSON.pretty_generate(self, options)
		{:iMatchNumber => @iMatchNumber, :sCompetitionLevel => @sCompetitionLevel, :sEventCode => @sEventCode, :teamMatchList => @teamMatchList}.to_json(options)
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

  def to_json(options)
    # JSON.pretty_generate(self, options)
    {:sTeamName => @sTeamName, :iTeamNumber => @iTeamNumber, :awardsList => @awardsList, :avgGearsPerMatch => @avgGearsPerMatch, :avgHighFuelPerMatch => @avgHighFuelPerMatch, :avgLowFuelPerMatch => @avgLowFuelPerMatch, :avgRankingPoints => @avgRankingPoints}.to_json(options)
  end
end

class MatchEvent #many per TeamMatch
  def initialize(timStamp, pointVal, cnt, isauto, eventname, location)
    @iTimeStamp = timStamp #how much time
    @iPointValue = pointVal #how many point earned
    @iCount = cnt #how many time
    @bInAutonomous = isauto #happened in autonomous yes/no
    @sEventName = eventName #what kind of thing happened - LOAD_HOPPER, CLIMB_FAIL, etc
    @loc = location #Point object
  end

  def to_json(options)
    # JSON.pretty_generate(self, options)
    {:iTimeStamp => @iTimeStamp, :iPointValue => @iPointValue, :iCount => @iCount, :bInAutonomous => @bInAutonomous, :sEventName => @sEventName, :loc => @loc}.to_json(options)
  end
end

class Point
  def initialize(myx, myy)
    @x = myx
    @y = myy
  end
  def to_json(options = {})
    # JSON.pretty_generate(self, options)
    {:x => @x, :y => @y}.to_json(options)
  end
end

class SimpleTeam
  def initialize(teamname, teamnumber)
    @sTeamName = teamname
    @iTeamNumber = teamnumber
  end

  def to_json(options)
    # JSON.pretty_generate(self, options)
    {:sTeamName => @sTeamName, :iTeamNumber => @iTeamNumber}.to_json(options)
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
	def to_json(options)
    # JSON.pretty_generate(self, options)
		{iTeamNumber: @iTeamNumber, iMatchNumber: @iMatchNumber, iStationNumber: @iStationNumber, iAllianceNumber: @iAllianceNumber, sNotes: @sNotes, sEventCode: @sEventCode, sPersonScouting: @sPersonScouting, bColor: @bColor, matchEventList: @matchEventList}.to_json(options)
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

def saveEventsData(frcEvents)
	frcEvents.each do |event|
		filename = "public/Events/" + event.sEventCode + ".json"
        if(File.exist? filename)
            puts("Overwriting existing file #{filename}")
        else
            puts("Creating new file #{filename}")
        end
        jsonfile = File.open(filename,'w')
		jsonfile << event.to_json(options = {})
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
	jsonfile << jsondata.to_json #array of all MatchEvent objects into file. maybe?
	jsonfile.close
	#Possible extra task: compare existing json to saved json in case of double-saving
	puts "Successfully saved " + filename

	puts "Here are some analytics"
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
	jsonfile << jsondata.to_json
	jsonfile.close
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

$scoresjson = {}
$qualdetailsjson = {}
$playoffetailsjson = {}
$ranksjson = {}
#{'CASJ': {}, 'ABCA': {}, etc}

def updateEventFromAPI(eventcode,lastmodified)
	#reqapi for all the latest data
	#first check if-modified-since (I do not know where to get lastmodified atm)
	#then overwrite all data, in case a correction was made, as it's all the same call anyway
	#finally, return a success/failure message
end

def updateScores(eventcode)
	puts "Begin update scores"
	matches = reqapi("matches/#{eventcode}") #Provides scores, teams
	puts "We got matches look #{matches}"
	#qualdetails = reqapi("scores/#{eventcode}/qual") 
	#playoffdetails = reqapi("scores/#{eventcode}/playoff") #Data sweet data! Subject to change.
	#puts "We got qualdetails look #{qualdetails}"
	$scoresjson[eventcode] = JSON.parse(matches)
	#$qualdetailsjson[eventcode] = JSON.parse(qualdetails)
	#$playoffdetailsjson[eventcode] = JSON.parse(playoffdetails)
	
	#If-Modified-Since is very important here if we can implement it
	#So is the parameter start= for matches we already have

	#INCOMPLETE: This method cannot be finished until the 2017 API is complete
end

def updateRanks(eventcode)
	ranks = reqapi("rankings/#{eventcode}")
	ranksjson[eventcode] = JSON.parse(ranks)
end

def analyzeTeamAtEvent(teamnumber, eventcode)
	#1. Collect all files related to the team and event
	#2. Update scores and other data from the API
	#3. Holistic analyses - games scouted, played, won
	#4. MatchEvent analyses
	#5. Compatibility analyses
	#6. Future predictions / z-score / pick-ban
	#7. Upcoming matches

	puts "Begin analysis for #{teamnumber} at #{eventcode}"

	analysis = {} #The hash to be returned as JSON

	filenames = [] #Names of all relevant files
	pitfilenames = [] #Files for pit scouting
	teammatchfilenames = [] #Files for match scouting
	
	#Main data to handle
	matchevents = []
	matchnums = []
	scores = []

	#Qualitative / scout opinions
	speedscores = [] #Ints: 0-5
	weightscores = [] #Ints: 0-5
	roles = [] #Strings: SHOT, GEAR, DEF, AUTO
	donotpick = [] #Booleans: True/False

	Dir.glob("public/Teams/#{teamnumber}/#{eventcode}_Pit_Team#{teamnumber}.json") do |filename|
		filenames << filename
		pitfilenames << filename
	end
	Dir.glob("public/TeamMatches/#{eventcode}_TeamMatch*_Team#{teamnumber}.json") do |filename|
		filenames << filename
		teammatchfilenames << filename
	end
	if filenames.size #If the number of relevant files is not 0
		#combine similar json objects into arrays
		if pitfilenames.size #If there are pit files
			pitfilenames.each do |filename| #Go through the files
				puts "I am going through #{filename}"
				tempjson = retrieveJSON(filename) #Convert them to json
				#combine pit stuff (client-dependent)
				#until we know what is being scouted from the pit, ignore this for now
			end #end pitfilenames foreach
		end #end if pitfilenames.size
		if teammatchfilenames.size #If there are match files
			teammatchfilenames.each do |filename| #Go through the files
				puts "I am going through #{filename}"
				tempjson = retrieveJSON(filename) #Convert them to json
				if tempjson['matchEvents'] #If this json has a list of match events
					tempjson['matchEvents'].each do |matchevent| #Go through the match events
						matchevents << matchevent #Add the matchevents to an array of team's match events
					end #end matchevents foreach
				end #end if tempjson['matchEvents']
				if tempjson['iMatchNumber'] #If this json has a match number
					matchnums << tempjson['iMatchNumber'] #Add the matchnumber to an array of team's matchnums
				end #end if tempjson['iMatchNumber']
				
				#Scout opinions - optional parameters
				speedscores << tempjson['iSpeed'] if tempjson['iSpeed']
				weightscores << tempjson['iWeight'] if tempjson['iWeight']
				
				donotpick << (tempjson['bDonotPick'] ? true : false)
				roles << tempjson['sRole'] if tempjson['sRole']

			end #end teammatchfilenames foreach
		end #end if teammatchfilenames.size
	end #end if filenames.size

	updateScores(eventcode)

	#Analyze performance (winrate, rank, etc)
	analysis['iNumMatches'] = matchnums.length

	#Analyze match events (accuracy, contribution, etc)
	sortedevents = sortMatchEvents(matchevents) #Sort by what happens in each event
	analyzedevents = analyzeSortedEvents(sortedevents, matchnums.length) #Send out to analysis method instead of hard coding
	analyzedevents.each do |key, val|
		analysis[key] = val
	end

	#Analyze performance with and against other teams at event


	#Predictions

	#{"filesFound" => filenames}.to_json
	#{'matchEvents' => matchevents}.to_json
	analyzedevents.to_json
end

def analyzeTeamInMatch(teamnum, matchnum, eventname)
	#specific match-by-match, instead of holistic
end

def sortMatchEvents(matchevents = [])
	#Receives an array of match events
	#Returns a hash of arrays of match events
	#sort using sEventName
	puts "Sort match events"
	sortedevents = {}
	matchevents.each do |matchevent|
		key = matchevent['sEventName']
		val = matchevent
		unless sortedevents[key]
			sortedevents[key] = [] #Initialize array to hold multiple matchevents
		end
		sortedevents[key] << val #Add matchevent to array
		puts "We now have #{key}: #{sortedevents[key]}"
	end
	sortedevents
	
	#sortedevents['GEAR_SCORE'] => [matchevent1, matchevent2, ...] etc
end

def analyzeSortedEvents(sortedevents = [], nummatches)
	#Receives an array of relevant match events
	#Returns a hash of analytics
	analyzed = {}
	puts "Analyze match events"

	contribution = 0.0 #Contribution: The total, fully weighted estimate of how well a team will do
	#AKA z-score

	rpcontrib = 0.0 #RP Contribution: 1/3 of the amount of ranking points they would score if they had 3 robots
	qpcontrib = 0.0 #QP Contribution: the flat amount of points they contribute in qualifiers, including auto / fuel
	pcontrib = 0.0 #Playoffs Contribution: the amount of points they contribute in playoffs, including weighted RP bonus
	#NOTE: RPContrib DOES NOT include the 0, 1, or 2 RP earned from qualifier results

	#Set constants
	#In the future, if client is willing, we may want to make it so the viewer can request calculation with different constants!
	prepop_gears = 3 #Prepopulated gears, usually constant but "may change"
	total_gears_needed = 16 - prepop_gears #To turn all rotors #1, 2, 5 (-1), 8 (-2)
	avg_gears_needed = total_gears_needed / 4 #To turn one rotor
	rpcontrib_per_autogear, rpcontrib_per_telegear = (1.0 / total_gears_needed), (1.0 / total_gears_needed)
	qpcontrib_per_autogear = (60.0 / avg_gears_needed)
	qpcontrib_per_telegear = (40.0 / avg_gears_needed )
	pcontrib_per_autogear = (100.0 / total_gears_needed) + (60.0 / avg_gears_needed)*4
	pcontrib_per_telegear = (100.0 / total_gears_needed) + (40.0 / avg_gears_needed)*4 
	qpcontrib_per_touchpad, pcontrib_per_touchpad = 50.0, 50.0 #End w/touchpad (requires climb)
	qpcontrib_per_baseline, pcontrib_per_baseline = 5.0, 5.0 #Autonomous movement
	#Fuel goes here
	#WARNING: A gear in autonomous is worth slightly more than in teleop
	#This is because completing a rotor gives 60 points in auto, but 40 in tele 

	#Unpack sorted events
	load_hopper = [] if (load_hopper = sortedevents['LOAD_HOPPER']).nil?
	high_start = [] if (high_start = sortedevents['HIGH_GOAL_START']).nil?
	high_stop = [] if (high_stop = sortedevents['HIGH_GOAL_STOP']).nil?
	high_miss = [] if (high_miss = sortedevents['HIGH_GOAL_MISS']).nil?
	low_start = [] if (low_start = sortedevents['LOW_GOAL_START']).nil?
	low_stop = [] if (low_stop = sortedevents['LOW_GOAL_STOP']).nil?
	low_miss = [] if (low_miss = sortedevents['LOW_GOAL_MISS']).nil?
	gear_score = [] if (gear_score = sortedevents['GEAR_SCORE']).nil?
	gear_load = [] if (gear_score = sortedevents['GEAR_LOAD']).nil?
	gear_drop = [] if (gear_score = sortedevents['GEAR_DROP']).nil?


	#Begin working with numbers

	if gear_load.length > 0
		gScorePerLoad = gear_score.length.to_f / gear_load.length.to_f
		gDropPerLoad = gear_drop.length.to_f / gear_load.length.to_f
	else
		gScorePerLoad = -1.0
		gDropPerLoad = -1.0
	end
	analyzed['fGearAccuracy'] = gScorePerLoad
	analyzed['iGearsScored'] = gear_score.length
	analyzed['avgGearsPerMatch'] = analyzed['iGearsScored'].to_f / nummatches.to_f
	puts "Overall gear accuracy: #{analyzed['fGearAccuracy']}"
	puts "Total gears scored: #{analyzed['iGearsScored']}"
	puts "Average gears scored per match #{analysis['avgGearsPerMatch']}"

	if gear_score.length > 0
		gear_score.each do |event|
			if event['bInAutonomous']
				rpcontrib += rpcontrib_per_autogear
				qpcontrib += qpcontrib_per_autogear
				pcontrib += pcontrib_per_autogear
			else
				rpcontrib += rpcntrib_per_telegear
				qpcontrib += qpcontrib_per_telegear
				pcontrib += pcontrib_per_telegear
			end
		end
	end


	puts "Total RP Contribution: #{rpcontrib}"
	puts "Total QP Contribution: #{qpcontrib}"
	puts "Total Playoffs Contribution: #{pcontrib}"
	
	analyzed

	#games scouted, winrate
end

def matchScoreTimeline(sortedevents)
	#test
end

def matchString(teammatch)
	#Make a table: timestamps, match event type, team, human-readable note
	#This way we can see a match at a glance
end