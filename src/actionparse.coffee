class window.MoveAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
		@dx = dx
		@dy = dy

	step: (player) ->
		if @nSteps <= 0 
			# Need new action
			return false
		@nSteps--
		dx = @dx
		dy = @dy
		if player.map.isBlocked(player.x + dx, player.y + dy)
			# Need new action
			return false
		# TODO skirt around
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
