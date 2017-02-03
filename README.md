# ABOUT
The entire bee movie script except every bee is replaced with useful data and analytics.

# CONTRIBUTORS
Lauren Wang,
Ian Hunicke-Smith,
Honorable mention to the resident Ruby wizard Michael Watson

# GENERAL PLAN
* Interaction with FRC API and basic get/post requests by week 1
* Save and recall data by week 2
* Sort data by week 3
* Analyze data by week 4
* Team requested features (graphs, timelines,) by week 5
* Physical server, SSL cert by week 6
* Force juniors to understand / be able to debug by week 7
* PROFIT by week 8! :P

# TO-DO
* Receive JSON from FRC API
* Send JSON to Client (scout teams)
 * Event object
* Receive JSON from Client (scout teams)
 * TeamMatch object
* Sort Teams
 * Corresponding Matches
 * Previous Partners/Opponents
 * Winrate/Ranking
* Analysis - Teams
 * Robot (pit scouting)
 * Team personality?
 * Likelihood of robot breaking
* Analysis - Numbers
 * Early game
 * Mid game
 * Late game
 * Score
 * Sources of score
 * Winrate
* Predictions - Numbers
 * Score
 * Sources of score
* Send JSON to client (analytics)
* Handling Custom Notes
 * Sort per team
 * Highlights / common words
 * Good/bad reviews?
* Pick List
* Handling Possible Dangers
 * Out of memory
 * Thread timeout
 * Packet loss
 * Too much data too little time
 * Hackerman
* The Cloud
 * Get a host other than my PC
 * Configure domain name
 * Database integration
* Auhorization
 * FRC API compliant key (can't run the code without it - talk to Lauren)
 * Key separate from Github?
 * Obfuscation?
* Fun Stuff
 * The Doodle Tradition
 * Animations

# IAN VULT
Simulations
Slack Bot (Kate)

# NAMING CONVENTIONS
* Event string codes: stuff that happens in a match. https://docs.google.com/document/d/1R51aN8jQxovCz6G7pOAtSW9ZRAhzVhrsSbaVJhcE8u0/edit?usp=sharing

# TO CONTRIBUTE: do these first!
Do this in Git.

git clone https://github.com/2468scout/2468Scout-Ruby-Server.git

Run this in Git. Make sure apitoken.txt is gitignore'd, as it cannot be posted publicly. Seriously.

echo TOKENGOESHERE >> apitoken.txt

Run this in Ruby.

gem install sinatra-contrib