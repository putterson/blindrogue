class window.MoveAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
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
		[dx, dy] = @_findDirection(player)
		player.move(dx, dy)

parseDirection = (dir) ->
	if dir in ["n", "north", "up", "u"]
		return [0,-1]
	if dir in ["s", "south", "down", "d"]
		return [0,1]
	if dir in ["e", "east", "right", "r"]
		return [1,0]
	if dir in ["w", "west", "left", "l"]
		return [-1,0]

	if dir in ["ne", "northeast", "upright", "ur"]
		return [1,-1]
	if dir in ["nw", "northwest", "upleft", "ul"]
		return [-1,-1]
	if dir in ["se", "southeast", "downright", "dr"]
		return [1,1]
	if dir in ["sw", "southwest", "downleft", "dl"]
		return [-1,1]
	return null

MOVE_WORDS = ["g", "go", "m", "move"]
STEP_WORDS = ["s", "step"]
LOOK_WORDS = ["look", "describe"]

window.parseAction = (line) ->
	parts = line.split(" ")
	verb = parts[0].toLowerCase()
	if parts.length >= 2
		# Create the last verb by gluing together the last components
		rest = ''
		for i in [1 ..  parts.length-1]
			rest += parts[i]

		isMove = (verb in MOVE_WORDS) 
		isStep = (verb in STEP_WORDS)
		
		if isMove or isStep
			dir = parseDirection(rest.toLowerCase())
			if dir == null
				return "Direction " + parts[1] + " could not be understood!"
			return new MoveAction((if isStep then 1 else 3), dir[0], dir[1])
	else if parts.length == 1
		isLook = (verb in LOOK_WORDS)
		if isLook
			return "describe"
	return "Action could not be understood!"
