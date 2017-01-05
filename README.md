# ABOUT
The entire bee movie script except every bee is replaced with useful data and analytics.

# CONTRIBUTORS
Lauren Wang
Kate Denier
Aroofa Mohammad

# TO-DO
Client Thread Creation
 > Port number 8080
 > Timeout
Receive JSON from Blue Alliance
Send JSON to Client (scout teams)
 > Team numbers each alliance
Receive JSON from Client (scout teams)
 > Depends on Ian
Sort Teams
 > Corresponding Matches
 > Previous Partners/Opponents
 > Winrate/Ranking
Analysis - Teams
 > Robot (pit scouting)
 > Team personality?
 > Likelihood of robot breaking
Analysis - Numbers
 > Early game
 > Mid game
 > Late game
 > Score
 > Sources of score
 > Winrate
Predictions - Numbers
 > Score
 > Sources of score
Send JSON to client (analytics)
Handling Custom Notes
 > Sort per team
 > Highlights / common words
 > Good/bad reviews?
Pick List
Handling Possible Dangers
 > Out of memory
 > Thread timeout
 > Packet loss
 > Too much data too little time
 > Hackerman
Auhorization
 > FRC API compliant key (can't run the code without it - talk to Lauren)
 > Key separate from Github?
 > Obfuscation?
Fun Stuff
 > The Doodle Tradition
 > Animations

#IAN WANTS
Simulations
Slack Bot

#TO CONTRIBUTE: do these first!
git clone https://github.com/2468scout/2468Scout-Ruby-Server.git #Do this in git.
gem install sinatra-contrib #Run this in Ruby.
echo TOKENGOESHERE >> apitoken #Run this in Ruby. Make sure apitoken is gitignore'd, as it cannot be posted publicly. Seriously.