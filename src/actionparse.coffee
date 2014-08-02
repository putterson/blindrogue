class window.MoveAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
		@dx = dx
		@dy = dy

	# Returns nil if no good direction could be found
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
		return [0,0]

	step: (player) ->
		if @nSteps <= 0 
			# Need new action
			return false
		@nSteps--
		[dx, dy] = @_findDirection(player)
		if dx == 0 and dy == 0
			# Need new direction
			return false
		player.move(dx, dy)
		# Keep going
		return true

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

window.parseAction = (line) ->
	parts = line.split(" ")
	verb = parts[0].toLowerCase()
	if verb in ["g", "go", "m", "move"]
		dir = parseDirection(parts[1].toLowerCase())
		if dir == null
			return "Direction " + parts[1] + " could not be understood!"
		return new MoveAction(3, dir[0], dir[1])
	return "Action could not be understood!"
