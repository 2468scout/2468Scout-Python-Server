#Set constants
#In the future, if client is willing, we may want to make it so the viewer can request calculation with different constants!
prepop_gears = [0, 0, 1, 2] #Prepopulated gears, usually constant but "may change"
rotor_gears = [1, 2, 5, 8] #Total 16
total_gears_needed = rotor_gears.inject(0, &:+) - prepop_gears.inject(0, &:+) #To turn all rotors #1 + 2 + 5 (- 1) + 8 (- 2)
avg_gears_needed = total_gears_needed / 4 #To turn one rotor
rp_per_autogear, rp_per_telegear = (1.0 / total_gears_needed), (1.0 / total_gears_needed)
qp_per_autogear = (60.0 / avg_gears_needed)
qp_per_telegear = (40.0 / avg_gears_needed )
p_per_autogear = (100.0 / total_gears_needed) + (60.0 / avg_gears_needed)*4
p_per_telegear = (100.0 / total_gears_needed) + (40.0 / avg_gears_needed)*4 
qp_per_touchpad, p_per_touchpad = 50.0, 50.0 #End w/touchpad (requires climb)
qp_per_undotouchpad, p_per_undotouchpad = -50.0, -50.0 #Disengage from touchpad prematurely
qp_per_baseline, p_per_baseline = 5.0, 5.0 #Autonomous movement
#Fuel goes here
#Fuel guessing only


#NOTE: A gear in autonomous is worth slightly more than in teleop.
#This is because completing a rotor gives 60 points in auto, but 40 in tele 



################################################
##############BEGIN FILE HANDLING###############
################################################

#Filename format:
#Eventcode_Objecttype_Teamnum.json
#Objecttype: Pit, TeamMatch, Match, ScoreScout
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
end

def saveTeamPitInfo(jsondata)
	jsondata = JSON.parse(jsondata)
	eventcode = jsondata['sEventCode']
	teamnumber = jsondata['iTeamNumber']
	filename = "public/Teams/#{teamnumber}/#{eventcode}_Pit_Team#{teamnumber}.json"
	
	#existingjson = '{}'
	#if File.exists? filename
	#	existingjson = retrieveJSON(filename)
	#end
	
	jsonfile = File.open(filename,'w')
	jsonfile << jsondata.to_json
	jsonfile.close
end

def saveScoreScoutInfo(jsondata)
	jsondata = JSON.parse(jsondata)
	eventcode = jsondata['sEventCode']
	matchnumber = jsondata['iMatchNumber']
	side = "Null"
	side = "Blue" if jsondata['bColor'] == true
	side = "Red" if jsondata['bColor'] == false
	filename = "public/Scores/#{eventcode}_Score#{matchnumber}_Side#{side}"
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
##############BEGIN API RETRIEVAL###############
################################################

$scoresjson = {} #'CASJ': [{match},{match}]
$qualdetailsjson = {}
$playoffetailsjson = {}
$ranksjson = {}
#For all of these, format as {'CASJ': {}, 'ABCA': {}, etc}

def updateEventFromAPI(eventcode)
	#reqapi for all the latest data
	#then overwrite all data, in case a correction was made, as it's all the same call anyway
	#finally, return a success/failure message
	updateScores(eventcode)
	updateRanks(eventcode)
end

def updateScores(eventcode)
	puts "Begin update scores"
	matchresults = reqapi("matches/#{eventcode}",true) #Provides scores, teams
	puts "We got matches look #{matches}"
	#qualdetails = reqapi("scores/#{eventcode}/qual") 
	#playoffdetails = reqapi("scores/#{eventcode}/playoff") #Data sweet data! Subject to change.
	#puts "We got qualdetails look #{qualdetails}"
	$scoresjson["#{eventcode}"] = []
	matchresults["Matches"].each do |matchresult|
		$scoresjson["#{eventcode}"] << JSON.parse(matchresult)
	end
	#$qualdetailsjson[eventcode] = JSON.parse(qualdetails)
	#$playoffdetailsjson[eventcode] = JSON.parse(playoffdetails)
	
	#If-Modified-Since is very important here if we can implement it
	#So is the parameter start= for matches we already have

	#INCOMPLETE: This method cannot be finished until the 2017 API is complete
	$scoresjson["#{eventcode}"]
end

def getScores(eventcode)
	if $scoresjson["#{eventcode}"] #We already have scores
		return $scoresjson["#{eventcode}"]
	elsif updateScores("#{eventcode}") #No scores yet so we will update from API
		return $scoresjson["#{eventcode}"]
	else #No scores saved nor available on API
		return '{}'
	end
end

def updateRanks(eventcode)
	ranks = reqapi("rankings/#{eventcode}",true)
	$ranksjson["#{eventcode}"] = JSON.parse(ranks)
end

################################################
#############BEGIN RAWDATA SORTING##############
################################################

def sortMatchEvents(matchevents = [])
	#Receives an array of match events
	#Returns a hash of arrays of match events
	#sort using sEventName
	puts "Sort match events"
	sortedevents = {}
	autoevents = []
	matchevents.each do |matchevent|
		key = matchevent['sEventName']
		val = matchevent
		unless sortedevents[key]
			sortedevents[key] = [] #Initialize array to hold multiple matchevents
		end
		sortedevents[key] << val #Add matchevent to array
		puts "We now have #{key}: #{sortedevents[key]}"
		if val['bInAutonomous']
			autoevents << val
		end
	end
	sortedevents["AUTOSTUFF"] = autoevents if autoevents.length > 0 #Additional separate array to isolate autonomous
	sortedevents
	
	#sortedevents['GEAR_SCORE'] => [matchevent1, matchevent2, ...] etc
end

################################################
##############BEGIN FUEL GUESSING###############
################################################

def addSubscoreScout(data, arrayname, val, scorehash)
	data[arrayname].each do |ms|
		scorehash[ms] = 0 unless scorehash[ms]
		scorehash[ms] += val
	end
end

def scoreMatchEvents(sortedevents, scorehash)
	sortedevents.each do |eventarray|
		eventarray.each do |matchevent|
			timestamp = matchevent['iTimeStamp']
			scorehash[timestamp] = [] unless scorehash[timestamp]
			#Option 1: Define a hash at the top with the constants, and key matchevent names to score values
			#Option 2: Gigantic case switch, like in the main analytics method, in which accurate but longer calculations are made
			#So... efficiency? Or accuracy?
		end
	end
end

def analyzeScoreScouting(eventcode, matchnumber, matchcolor = true)
	#Prepare scorescouting for guessing fuel
	#Should return {'# milliseconds': score difference}
	#Lots of approximation, since 4 scouts will have different reaction times
	descrepancies = {}

	matchevents = [] #We need all the matchevents that happened in the match
	sortedmatchevents = {}
	Dir.glob("public/TeamMatches/#{eventcode}_TeamMatch#{matchnumber}_*.json") do |filename|
		tempjson = retrieveJSON(filename)
		break unless tempjson['bColor'] == matchcolor #blue is true
		
		if tempjson['MatchEvents']
			tempjson['MatchEvents'].each do |matchevent|
				matchevents << matchevent
			end
		end
	end
	sortedmatchevents = sortMatchEvents(matchevents)

	scorescout = '{}'
	side = "Null"
	side = "Blue" if matchcolor == true
	side = "Red" if matchcolor == false
	filename = "public/Scores/#{eventcode}_Score#{matchnumber}_Side#{side}"
	scorescout = retrieveJSON(filename)
	#bColor, increase(1,5,40,50,60)TimeList []

	#Time to calculate the differences.
	#Idea: do this like a simulation for a game
	#Each millisecond is a 'turn' and each event is a 'move'
	scoutedscore = 0
	matchscore = 0
	
	#Testing idea 1
	#combine them all into one big hash, with the points and timestamp?
	addscores = {} #points the scorescout says there are
	addSubscoreScout(scorescout, 'increase1TimeList', 1, addscores)
	addSubscoreScout(scorescout, 'increase5TimeList', 5, addscores)
	addSubscoreScout(scorescout, 'increase40TimeList', 40, addscores)
	addSubscoreScout(scorescout, 'increase50TimeList', 50, addscores)
	addSubscoreScout(scorescout, 'increase60TimeList', 60, addscores)
	addSubscoreScout(scorescout, 'decrease50TimeList', -50, addscores)

	nonfuel = {} #points the matchscouts say there are
	#ian stuff

	#order by time, add scouted scores, match scores,
	#difference for .. each second? each millisecond?
end

def guessFuel(teams, startevents, stopevents, misses, scores, matchcolor) #startevents = [[team1],[team2],[team3]]
	puts "Guess fuel"
	result = 0.0
	deviation = 0.0
	lintervals = [] #[[start, stop, teamnum],[start, stop, teamnum]]
	hintervals = []
	if (startevents.length - stopevents.length).abs > 1 #Scout client error
		puts "WARNING: The difference between number of stopevents and startevents is greater than 1. Expect errors!"
	end

	0..(teams.length - 1) do |j|
		teamnumber = teams[j]['iTeamNumber']

		matchevents = [] #We need all the matchevents that happened in the match
		sortedmatchevents = {}
		Dir.glob("public/TeamMatches/#{eventcode}_TeamMatch#{matchnumber}_#{teamnumber}.json") do |filename|
			tempjson = retrieveJSON(filename)
			break unless tempjson['bColor'] == matchcolor #blue is true
			if tempjson['MatchEvents']
				tempjson['MatchEvents'].each do |matchevent|
					matchevents << matchevent
				end
			end
		end
		sortedmatchevents = sortMatchEvents(matchevents)
		lstartevents = sortedmatchevents['LOW_GOAL_START']
		lstopevents = sortedmatchevents['LOW_GOAL_STOP']
		hstartevents = sortedmatchevents['HIGH_GOAL_START']
		hstopevents = sortedmatchevents['HIGH_GOAL_STOP']

		#Intervals in which the robot was shooting
		lstartevents.each do |startevent|
			lintervals << [startevent['iTimeStamp']]
		end
		0..(lstopevents.length - 1) do |i| #Pair start times with stop times
			if lintervals[i][0] > lstopevents[i]['iTimestamp'] #start time > stop time
				puts "WARNING: The robot stopped shooting before it started?!"
			end
			lintervals[i] << lstopevents[i]['iTimeStamp']
			lintervals[i] << teams[j]
		end
		if lintervals[lintervals.length - 1].length == 1 #Robot started shooting and never stopped
			lintervals[lintervals.length - 1] << 150 * 1000 #Fill in that it stopped at the end of the match
			lintervals[lintervals.length - 1] << teams[j]
		end

		hstartevents.each do |startevent|
			hintervals << [startevent['iTimeStamp']]
		end
		0..(hstopevents.length - 1) do |i| #Pair start times with stop times
			if hintervals[i][0] > hstopevents[i]['iTimestamp'] #start time > stop time
				puts "WARNING: The robot stopped shooting before it started?!"
			end
			hintervals[i] << hstopevents[i]['iTimeStamp']
			hintervals[i] << teams[j]
		end
		if hintervals[hintervals.length - 1].length == 1 #Robot started shooting and never stopped
			hintervals[hintervals.length - 1] << 150 * 1000 #Fill in that it stopped at the end of the match
			hintervals[hintervals.length - 1] << teams[j]
		end
	end
	#We're going to need to do this for all 3 robots on the alliance...

	#Match interval starts / stops as > and < for score times
	#Add to special list in which the things that might possibly be scored by which teams
	#intervals.each
		#increases.each
			#if in time frame, add to possibilities

	#Possible scores
	#possibilities.each
		#if more than one team
			#if matchnumber < 20, give average to each team
			#else weight contributions depending on past averages of each team

	#Match increase1TimeList to shooting times

	puts "I think that #{result} fuel was scored within a #{deviation} uncertainty."
	return result
end

################################################
###############BEGIN BIG ANALYSES###############
################################################

def analyzeTeamAtEvent(teamnumber, eventcode)
	#1. Collect all files related to the team and event
	#2. Update scores and other data from the API
	#3. Holistic analyses - games scouted, played, won
	#4. MatchEvent analyses
	#5. Compatibility analyses
	#6. Future predictions / z-score / pick-ban
	#7. Upcoming matches

	analysisstart = Time.now
	puts "Analyze #{teamnumber} at event #{eventcode} begun at #{analysisstart}!"

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
	updateRanks(eventcode)

	#Analyze performance (winrate, rank, etc)
	analysis['iNumMatches'] = matchnums.length
	teamrank = $ranksjson['Rankings'].find {|i| i['teamNumber'].to_s === teamnumber.to_s}
	analysis['iRank'] = teamrank['rank']
	analysis['iWins'] = teamrank['wins']
	analysis['iLosses'] = teamrank['losses']
	analysis['iTies'] = teamrank['ties']
	analysis['fWinRate'] = teamrank['wins'] / teamrank['matchesPlayed']
	analysis['fQPAverage'] = teamrank['qualAverage'] #Total points scored in quals / number of matches
	analysis['iTimesDisqualified'] = teamrank['dq']
	analysis['sWTL'] = "#{teamrank['wins']} / #{teamrank['ties']} / #{teamrank['losses']}" #Wins / Ties / Losses string

	#Add pit info
	#IANNNNNNNNNNNNNNNNN

	#Analyze match events (accuracy, contribution, etc)
	sortedevents = sortMatchEvents(matchevents) #Sort by what happens in each event
	analyzedevents = analyzeSortedEvents(sortedevents, matchnums.length) #Send out to analysis method instead of hard coding
	analyzedevents.each do |key, val|
		analysis[key] = val
	end

	#Analyze performance with and against other teams at event


	#Predictions


	analysisend = Time.now
	analysistime = analysisstart.to_f - analysisend.to_f
	puts "Analyze #{teamnumber} at event #{eventcode} completed at #{analysisend} for a total time of #{analysistime} seconds!"

	analysis.to_json
end

def analyzeTeamInMatch(teamnum, matchnum, eventname)
	#specific match-by-match, instead of holistic
end

def analyzeSortedEvents(sortedevents = [], nummatches)
	#Receives an array of relevant match events
	#Returns a hash of analytics
	analysisstart = Time.now
	puts "Analyze match events starting at #{analysisstart}"

	analyzed = {}

	contribution = 0.0 #Contribution: The total, fully weighted estimate of how well a team will do
	#AKA z-score

	rpcontrib = 0.0 #RP Contribution: 1/3 of the amount of ranking points they would have contributed if they had 3 robots
	qpcontrib = 0.0 #QP Contribution: the flat amount of points they contribute in qualifiers, including auto / fuel
	pcontrib = 0.0 #Playoffs Contribution: the amount of points they contribute in playoffs, including weighted RP bonus
	#NOTE: RPContrib DOES NOT include the 0, 1, or 2 RP earned from qualifier results
	#Partial credit is awarded for not enough gears, or not enough fuel; but gears and fuel can each contribute a max of 1.0

	totalmatches = nummatches #How many matches we have scouted the team in
	totalgearmtaches = 0 #How many matches the team has played in which they scored at least one gear
	totaltouchpadmatches = 0
	totalbaselinematches = 0

	#Unpack sorted events
	#Stuff that scores points
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
	climb_success = [] if (climb_success = sortedevents['CLIMB_SUCCESS']).nil?
	climb_fail = [] if (climb_fail = sortedevents['CLIMB_FAIL']).nil?
	touchpad = [] if (touchpad = sortedevents['TOUCHPAD']).nil?
	undo_touchpad = [] if (undo_touchpad = sortedevents['UNDO_TOUCHPAD']).nil?
	baseline = [] if (baseline = sortedevents['BASELINE']).nil?
	#Qualities about the robot
	defending = [] if (defending = sortedevents['DEFENDING']).nil?
	carry_capacity = [] if (carry_capacity = sortedevents['CARRY_CAPACITY']).nil?
	speed = [] if (speed = sortedevents['SPEED']).nil?
	mechanical_failure = [] if (mechanical_failure = sortedevents['MECHANICAL_FAILURE']).nil?

	#Inaccurate stuff
	#highfuel = guessHighFuel(high_start, high_stop, high_miss, scores)
	#lowfuel = guessLowFuel(low_start, low_stop, low_miss, scores)

	#Begin working with numbers
	###AUTONOMOUS BASELINE###
	if baseline.length > 0
		basematches = {} #Key: matchnum, val: {points to contrib}
		qptocontrib, ptocontrib = 0.0, 0.0
		baseline.each do |event|
			temp = event['iMatchNumber']
			basematches[temp] = {} unless basematches[temp]
			if event['bInAutonomous']
				basematches[temp]['qptocontrib'] += qp_per_baseline
				basematches[temp]['ptocontrib'] += p_per_baseline
			end
			
			#Safeguards to prevent overvaluing
			basematches[temp]['qptocontrib'] = 5.0 if basematches[temp]['qptocontrib'] > 50.0
			basematches[temp]['ptocontrib'] = 5.0 if basematches[temp]['ptocontrib'] > 50.0
		end

		basematches.each do |key, val| #Add contribution for each match
			#Standard deviation should be calculated here in the future

			baseqpcontrib += basematches[key]['qptocontrib'] #Use baseqpcontrib instead of qpcontrib
			basepcontrib += basematches[key]['ptocontrib'] #This way we know what scores came from where
		end

		qpcontrib += baseqpcontrib
		pcontrib += basepcontrib
		totalbaselinematches = basematches.length
	end
	analyzed['iTotalBaselineMatches'] = totalbaselinematches
	puts "This team has contributed #{baseqpcontrib} QP worth of baseline crossing points over #{totalbaselinematches} matches of attempting!"

	###GEARS###
	if gear_load.length > 0
		gScorePerLoad = gear_score.length.to_f / gear_load.length.to_f
		gDropPerLoad = gear_drop.length.to_f / gear_load.length.to_f
	else
		gScorePerLoad = -1.0
		gDropPerLoad = -1.0
	end
	analyzed['fGearAccuracy'] = gScorePerLoad
	analyzed['iGearsScored'] = gear_score.length
	analyzed['fAvgGearsPerMatch'] = analyzed['iGearsScored'].to_f / nummatches.to_f
	puts "*Overall gear accuracy: #{analyzed['fGearAccuracy']}"
	puts "*Total gears scored: #{analyzed['iGearsScored']}"
	puts "*Average gears scored per match #{analysis['avgGearsPerMatch']}"

	gearrpcontrib = 0.0
	gearqpcontrib = 0.0
	gearpcontrib = 0.0
	if gear_score.length > 0
		gearmatches = {} #Key: matchnum, val: {points to contrib}
		rptocontrib, qptocontrib, ptocontrib = 0.0, 0.0, 0.0
		gear_score.each do |event|
			temp = event['iMatchNumber']
			gearmatches[temp] = {} unless gearmatches[temp]
			if event['bInAutonomous'] #Rotor turning is valued differently depending on when the gear is scored
				gearmatches[temp]['rptocontrib'] += rp_per_autogear
				gearmatches[temp]['qptocontrib'] += qp_per_autogear
				gearmatches[temp]['ptocontrib'] += p_per_autogear
			else
				gearmatches[temp]['rptocontrib'] += rp_per_telegear
				gearmatches[temp]['qptocontrib'] += qp_per_telegear
				gearmatches[temp]['ptocontrib'] += p_per_telegear
			end
			
			#Safeguards to prevent overvaluing
			gearmatches[temp]['rptocontrib'] = 1.0 if gearmatches[temp]['rptcontrib'] > 1.0
			gearmatches[temp]['qptocontrib'] = 240.0 if gearmatches[temp]['qptocontrib'] > 240.0
			gearmatches[temp]['ptocontrib'] = 340.0 if gearmatches[temp]['ptocontrib'] > 340.0
		end

		gearmatches.each do |key, val| #Add contribution for each match
			#Standard deviation should be calculated here in the future

			gearrpcontrib += gearmatches[key]['rptocontrib']
			gearqpcontrib += gearmatches[key]['qptocontrib']
			gearpcontrib += gearmatches[key]['ptocontrib']
		end

		rpcontrib += gearrpcontrib
		qpcontrib += gearqpcontrib
		rpcontrib += gearpcontrib
		totalgearmatches = gearmatches.length
	end
	analyzed['iTotalGearMatches'] = totalgearmatches
	puts "This team has contibuted #{gearrpcontrib} RP worth of gears (#{gearqpcontrib} QP) over #{totalgearmatches} matches of attempting!"


	###CLIMB###
	touchqpcontrib = 0.0
	touchpcontrib = 0.0
	if touchpad.length > 0
		touchmatches = {} #Key: matchnum, val: {points to contrib}
		qptocontrib, ptocontrib = 0.0, 0.0
		touchpad.each do |event|
			temp = event['iMatchNumber']
			touchmatches[temp] = {} unless touchmatches[temp]
			
			touchmatches[temp]['qptocontrib'] += qp_per_touchpad
			touchmatches[temp]['ptocontrib'] += p_per_touchpad
			
			#Safeguards to prevent overvaluing
			touchmatches[temp]['qptocontrib'] = 50.0 if touchmatches[temp]['qptocontrib'] > 50.0
			touchmatches[temp]['ptocontrib'] = 50.0 if touchmatches[temp]['ptocontrib'] > 50.0
		end

		touchmatches.each do |key, val| #Add contribution for each match
			#Standard deviation should be calculated here in the future

			touchqpcontrib += touchmatches[key]['qptocontrib']
			touchpcontrib += touchmatches[key]['ptocontrib']
		end

		qpcontrib += touchqpcontrib
		pcontrib += touchpcontrib

		totaltouchpadmatches = touchmatches.length
	end
	analyzed['iTotalTouchpadMatches'] = totaltouchpadmatches
	puts "This team has contributed #{touchqpcontrib} QP worth of climb/touchpad points over #{totaltouchpadmatches} matches of attempting!"

	puts "Total RP Contribution: #{rpcontrib}"
	puts "--From gears: #{gearrpcontrib}"
	puts "Total QP Contribution: #{qpcontrib}"
	puts "--From crossing the baseline: #{baseqpcontrib}"
	puts "--From gears: #{gearqpcontrib}"
	puts "--From touchpad: #{touchqpcontrib}"
	puts "Estimated Playoffs Contribution: #{pcontrib}"

	analyzed['fBaseQPContrib'] = baseqpcontrib
	analyzed['fBasePContrib'] = basepcontrib

	analyzed['fGearRPContrib'] = gearrpcontrib
	analyzed['fGearQPContrib'] = gearqpcontrib
	analyzed['fGearPContrib'] = gearpcontrib

	analyzed['fTouchQPContrib'] = touchqpcontrib
	analyzed['fTouchPContrib'] = touchpcontrib

	#Assign these at the very end
	analyzed['fRPContrib'] = rpcontrib / nummatches.to_f
	analyzed['fQPContrib'] = qpcontrib / nummatches.to_f
	analyzed['fPlayoffContrib'] = pcontrib / nummatches.to_f
	analyzed['fContribution'] = contribution

	analysisend = Time.now
	analysistime = analysisstart.to_f - analysisend.to_f
	puts "Analyze match events completed at #{analysisend} for a total time of #{analysistime} seconds!"

	analyzed

	#games scouted, winrate
	#change over time
end

################################################
############BEGIN STRINGIFY METHODS#############
################################################

def matchScoreTimeline(sortedevents)
	#test
end

def matchTable(eventcode, matchnumber)
	#Make a table: timestamps, match event type, team, human-readable note
	#This way we can see a match at a glance
	filename = []
	Dir.glob("public/TeamMatches/#{eventcode}_TeamMatch#{matchnumber}_*.json") do |filename|
		filenames << filename
	end

	#Will be an array of arrays, each array contains a row of each table
	happened = [] #[[time (int), matcheventcode (string), team (int)'],[,,],etc]
	teammatches = []
	filenames.each do |filename|
		filedata = retrieveJSON(filename)
		teammatches << filedata
	end
	teammatches.each do |teammatch|
		matchevents = teammatch.matchEventList
		matchevents.each do |matchevent|
			happened[matchevent['iTimeStamp']] = [] unless happened[matchevent['iTimeStamp']]
			happened[matchevent['iTimeStamp']] << [matchevent['iTimeStamp'],matchevent['sEventName'],teammatch['iTeamNumber']]
		end
	end
	happened
end

def upcomingMatchSummary()
	#PRIORITY ORDER
	#alliance partners: performance, strengths and weaknesses
	#opponents: performance, strengths and weaknesses
	#heat maps

	#SimpleTeams
	#heat maps
	#elo / rankings
	#predicted roles
	#has been red carded ?
end

#Also - graph points
#progression over matches, heat maps, distribution wihin match