class global.BaseAction
	
	

class global.AttackAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
		@hasPerformed = false
		@dx = dx
		@dy = dy

	canPerform: (player) ->
		if @hasPerformed and player.map.objectTypeSeen(MonsterObj)
			# Only one step allowed when monsters nearby
			return false
		if @nSteps <= 0 
			# Need new action
			return false
		if not objFindFreeDirection(player, @dx, @dy)
			return false
		return true

	perform: (player) ->
		# Assumes canPerform!
		assert @canPerform(player)
		@nSteps--
		@hasPerformed = true
		[dx, dy] = objFindFreeDirection(player, @dx, @dy)
		player.move(dx, dy)

class global.MoveAction
	constructor: (nSteps, dx, dy) ->
		@nSteps = nSteps
		@hasPerformed = false
		@dx = dx
		@dy = dy

	canPerform: (player) ->
		if @hasPerformed and player.map.objectTypeSeen(MonsterObj)
			# Only one step allowed when monsters nearby
			return false
		if @nSteps <= 0 
			# Need new action
			return false
		if not objFindFreeDirection(player, @dx, @dy)
			return false
		return true

	perform: (player) ->
		# Assumes canPerform!
		assert @canPerform(player)
		@nSteps--
		@hasPerformed = true
		[dx, dy] = objFindFreeDirection(player, @dx, @dy)
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

createMoveIfPossible = (map, steps, [dx, dy]) ->
	action = new MoveAction(steps, dx, dy)
	if action.canPerform(map.player)
		return action
	# Otherwise, return error message
	return describeBlockingSquare(map, map.player.x + dx, map.player.y + dy)

parseTarget = (map, restLine) ->
	objs = map.seenObjects(MonsterObj)
	if objs.length == 0
		return "There is nothing to attack nearby!"
	if restLine == ""
		# Return closest enemy
		return objs[0]
	

MOVE_WORDS = ["move", "go", "g", "m"]
ATTACK_WORDS = ["attack", "fight", "a", "f"]
STEP_WORDS = ["step", "s"]
LOOK_WORDS = ["look", "describe", "l", "d"]

global.parseAction = (map, line) ->
	# Remove withspace, and lower-case the string
	line = line.replace(new RegExp(' ', 'g'),'').toLowerCase(); 

	# Try to parse the start of various actions.
	# Assignment intentional in if-statements.
	if (restLine = tryParse(line, MOVE_WORDS))
		# Try a short range travel
		dir = parseDirection(restLine)
		if dir == null
			return "Direction " +restLine+ " could not be understood!"
		return createMoveIfPossible map, 3, dir
	else if (restLine = tryParse(line, STEP_WORDS))
		# Try a step
		dir = parseDirection(restLine)
		if dir == null
			return "Direction " + restLine + " could not be understood!"
		return createMoveIfPossible map, 1, dir
	else if (restLine = tryParse(line, ATTACK_WORDS))
		target = parseTarget(map, restLine)
		if typeof target == 'string'
		 	return target
	else if line in LOOK_WORDS
		return "describe"
	return "Action could not be understood!"
