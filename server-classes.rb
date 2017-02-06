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