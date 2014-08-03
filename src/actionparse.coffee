class window.MoveAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
		@hasPerformed = false
		@dx = dx
		@dy = dy

	# Returns null if no good direction could be found
	_findDirection: (player) ->
		free = (dx, dy) -> not player.map.isBlocked(player.x + dx, player.y + dy)
		if free(@dx, @dy) 
			return [@dx, @dy]
		if @dx == 0
			if free(-1, @dy) 
				return [-1, @dy]
			if free(1, @dy)
				return [1, @dy]
		else if @dy == 0
			if free(@dx, 1)  
				return [@dx,  1]
			if free(@dx, -1) 
				return [@dx, -1]
		else 
			if free(@dx, 0)  
				return [@dx,  0]
			if free(0, @dy) 
				return [0, @dy]
		return null

	canPerform: (player) ->
		if @hasPerformed and player.map.objectTypeSeen(MonsterObj)
			# Only one step allowed when monsters nearby
			return false
		if @nSteps <= 0 
			# Need new action
			return false
		if not @_findDirection(player)
			return false
		return true

	perform: (player) ->
		# Assumes canPerform!
		assert @canPerform(player)
		@nSteps--
		@hasPerformed = true
		[dx, dy] = @_findDirection(player)
		player.move(dx, dy)

# Returns a string without a component, if the string starts with a component
tryParse = (text, words) ->
	for word in words
		if text.indexOf(word) == 0 # Starts with it
			return text.substring(word.length)
	return null

parseDirection = (dir) ->
	if dir in ["n", "north", "up", "u"]
		return [0,-1]
	if dir in ["s", "south", "down", "d"]
		return [0,1]
	if dir in ["e", "east", "right", "r"]
		return [1,0]
	if dir in ["w", "west", "left", "l"]
		return [-1,0]

	if dir in ["ne", "en", "northeast", "upright", "rightdown", "ur", "ru"]
		return [1,-1]
	if dir in ["nw", "wn", "northwest", "upleft", "leftup", "ul", "lu"]
		return [-1,-1]
	if dir in ["se", "es", "southeast", "downright", "rightdown", "dr", "rd"]
		return [1,1]
	if dir in ["sw", "ws", "southwest", "downleft", "leftdown", "dl", "ld"]
		return [-1,1]
	return null

MOVE_WORDS = ["move", "go", "g", "m"]
STEP_WORDS = ["step"]
LOOK_WORDS = ["look", "describe", "l", "d"]

window.parseAction = (line) ->
	# Remove withspace, and lower-case the string
	line = line.replace(new RegExp(' ', 'g'),'').toLowerCase(); 

	# Try to parse the start of various actions.
	# Assignment intentional in if-statements.
	if (restLine = tryParse(line, MOVE_WORDS))
		# Try a short range travel
		dir = parseDirection(restLine)
		if dir == null
			return "Direction " +restLine+ " could not be understood!"
		return new MoveAction(3, dir[0], dir[1])
	else if (restLine = tryParse(line, STEP_WORDS))
		# Try a step
		dir = parseDirection(restLine)
		if dir == null
			return "Direction " + restLine + " could not be understood!"
		return new MoveAction(1, dir[0], dir[1])
	else if line in LOOK_WORDS
		return "describe"
	return "Action could not be understood!"
