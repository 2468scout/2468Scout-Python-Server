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

	rpcontrib = 0.0 #RP Contribution: 1/3 of the amount of ranking points they would have contributed if they had 3 robots
	qpcontrib = 0.0 #QP Contribution: the flat amount of points they contribute in qualifiers, including auto / fuel
	pcontrib = 0.0 #Playoffs Contribution: the amount of points they contribute in playoffs, including weighted RP bonus
	#NOTE: RPContrib DOES NOT include the 0, 1, or 2 RP earned from qualifier results
	#Partial credit is awarded for not enough gears, or not enough fuel; but gears and fuel can each contribute a max of 1.0

	totalmatches = nummatches #How many matches we have scouted the team in
	totalgearmtaches = 0 #How many matches the team has played in which they scored at least one gear

	#Set constants
	#In the future, if client is willing, we may want to make it so the viewer can request calculation with different constants!
	prepop_gears = 3 #Prepopulated gears, usually constant but "may change"
	total_gears_needed = 16 - prepop_gears #To turn all rotors #1 + 2 + 5 (- 1) + 8 (- 2)
	avg_gears_needed = total_gears_needed / 4 #To turn one rotor
	rp_per_autogear, rp_per_telegear = (1.0 / total_gears_needed), (1.0 / total_gears_needed)
	qp_per_autogear = (60.0 / avg_gears_needed)
	qp_per_telegear = (40.0 / avg_gears_needed )
	p_per_autogear = (100.0 / total_gears_needed) + (60.0 / avg_gears_needed)*4
	p_per_telegear = (100.0 / total_gears_needed) + (40.0 / avg_gears_needed)*4 
	qp_per_touchpad, p_per_touchpad = 50.0, 50.0 #End w/touchpad (requires climb)
	qp_per_baseline, p_per_baseline = 5.0, 5.0 #Autonomous movement
	#Fuel goes here
	#NOTE: A gear in autonomous is worth slightly more than in teleop.
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
	climb_success = [] if (climb_success = sortedevents['CLIMB_SUCCESS']).nil?
	climb_fail = [] if (climb_fail = sortedevents['CLIMB_FAIL']).nil?
	touchpad = [] if (touchpad = sortedevents['TOUCHPAD']).nil?

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
	analyzed['fAvgGearsPerMatch'] = analyzed['iGearsScored'].to_f / nummatches.to_f
	puts "Overall gear accuracy: #{analyzed['fGearAccuracy']}"
	puts "Total gears scored: #{analyzed['iGearsScored']}"
	puts "Average gears scored per match #{analysis['avgGearsPerMatch']}"

	if gear_score.length > 0
		gearmatches = {} #Key: matchnum, val: {points to contrib}
		rptocontrib, qptocontrib, ptocontrib = 0, 0, 0
		gear_score.each do |event|
			temp = event['iMatchNumber']
			gearmatches[temp] = {} unless gearmatches[temp]
			if event['bInAutonomous']
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
			rpcontrib += gearmatches[key]['rptocontrib']
			qpcontrib += gearmatches[key]['qptocontrib']
			pcontrib += gearmatches[key]['ptocontrib']
		end

		totalgearmatches = gearmatches.length
	end
	analyzed['iTotalGearMatches'] = totalgearmatches


	puts "Total RP Contribution: #{rpcontrib}"
	puts "Total QP Contribution: #{qpcontrib}"
	puts "Total Playoffs Contribution: #{pcontrib}"
	
	#Assign these at the very end
	analyzed['fRPContrib'] = rpcontrib / nummatches.to_f
	analyzed['fQPContrib'] = qpcontrib / nummatches.to_f
	analyzed['fPlayoffContrib'] = pcontrib / nummatches.to_f
	analyzed['fContribution'] = contribution

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