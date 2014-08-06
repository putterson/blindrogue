
class global.MoveAction
	constructor: (nSteps, dx, dy, wordsUsed) ->
		@nSteps = nSteps
		@dx = dx
		@dy = dy
		@wordsUsed = wordsUsed

	isInterrupted: (obj) ->
		if obj.map.eventOccurred "PlayerWasAttacked"
			return [true, "You move carefully, you are being attacked!"]
		if obj.map.seenObjects(MonsterObj).length > 0
			return [true, "You move carefully due to nearby enemies."]
		else
			items = obj.map.seenObjects(ItemObj)
			newItems = []
			for item in items
				if not item.wasSeen
					newItems.push(item.getName())
			if newItems.length > 1
				return [true, "You stopped to look at the " + newItems.join(", ")]
			return [false]

	# No message attached because reason should be 'obvious'
	isComplete: (obj) -> (@nSteps <= 0)
	canPerform: (obj) ->
		if not objFindFreeDirection(obj, @dx, @dy)
			return [false, describeBlockingSquare(obj.map, obj.x + @dx, obj.y + @dy)]
		return [true]

	perform: (obj) ->
		@nSteps--
		[dx, dy] = objFindFreeDirection(obj, @dx, @dy)
		wordsUsed = @wordsUsed
		obj.map.events.push {type: "PlayerMove", message: "You move #{wordsUsed}."}
		obj.move(dx, dy)

class global.AttackAction
	constructor: (target) ->
		@didAttack = false
		@target = target

	isInterrupted: (obj) ->
		if obj.map.eventOccurred "PlayerWasAttacked"
			return [true, "You were interrupted by an enemy's attack!"]
		else
			return [false]

	isComplete: () -> @didAttack
	canPerform: (obj) ->
		if @target.isDead
			return [false, "The #{target.getName()} is already dead!"]

		dir = objDirTowards obj, @target, true # Use player sight
		if not dir
			return [false, "You have no route to the enemy!"]
		return [true]

	perform: (obj) ->
		@nSteps--
		if objNearby obj, @target
			obj.attack @target
		else
			[dx, dy] = objDirTowards obj, @target, true # Use player sight
			targetName = @target.getName()
			obj.map.events.push {type: "PlayerMove", message: "You move towards the #{targetName}."}
			obj.move(dx, dy)

dirToWordCombos = (dx, dy) ->
	words = []
	# Straight up/down
	if dx == +0 and dy == -1 then return ["north", 		"up"       				  ]
	if dx == +0 and dy == +1 then return ["south", 		"down"                    ]
	# Rightward
	if dx == +1 and dy == -1 then return ["north east", "up right",   "right up"  ]
	if dx == +1 and dy == 0  then return ["east",		"right"                   ]
	if dx == +1 and dy == +1 then return ["south east", "down right", "right down"]
	# Leftward
	if dx == -1 and dy == -1 then return ["north west", "up left",    "left up"   ]
	if dx == -1 and dy == 0  then return ["west", 		"left"                    ]
	if dx == -1 and dy == +1 then return ["south west", "down left",  "left down" ]
	assert false, "Bad dx=#{dx} dy=#{dy}!"

MOVE_WORDS = ["Move"]
ATTACK_WORDS = ["Attack", "Fight"]
ITEMGET_WORDS = ["Get"]
STEP_WORDS = ["Step"]
LOOK_WORDS = ["Look", "Describe"]

DIRECTIONS = ["north", "north east", "east", "south east", "south", "south west", "west", "north west"]
addAttackActions = (choices, map) ->
	# Holds enemies found in each direction
	directionBuckets = {}
	for dir in DIRECTIONS
		directionBuckets[dir] = []
	# Place enemies into buckets, closest enemies first (due to seenObjects call).
	for obj in map.seenObjects(MonsterObj)
		[dx,dy] = objApproxDirection(map.player, obj)
		# Take the first word (uses north etc instead of up/left etc)
		[bucket] = dirToWordCombos(dx, dy)
		console.log dx, dy, bucket
		directionBuckets[bucket].push(obj)
	# Create attack options from enemies seen
	for dir in DIRECTIONS
		i = 1
		for obj in directionBuckets[dir]
			for firstWord in ATTACK_WORDS
				words = [firstWord].concat(obj.getName().split " ").concat(dir.split " ")
				words.push i.toString()
				choices.push new ActionChoice(words,  new AttackAction(obj), "#{words.join " "}:\n Engage in melee combat, moving closer if necessary.")
			i++

addMoveActions = (choices, firstWords, nSteps) ->
	for firstWord in firstWords
		for dx in [-1 .. +1] 
			for dy in [-1 .. +1]
				if dx != 0 or dy != 0
					for dirWords in dirToWordCombos dx, dy
						words = [firstWord].concat(dirWords.split " ")
						choices.push new ActionChoice(words, new MoveAction(nSteps, dx, dy, dirWords))

addDescribeActions = (choices) ->
	for firstWord in LOOK_WORDS
		choices.push new ActionChoice([firstWord], "describe", "#{firstWord}\n Look around you.")
	choices.push new ActionChoice(["reveal"], "reveal", "Reveal\n Reveals the map for you, Mr. Cheater McCheaterson.")

createActionChoiceSet = (map) ->
	choices = []
	# Add step actions
	addMoveActions choices, STEP_WORDS, 1 
	# Add move actions
	addMoveActions choices, MOVE_WORDS, 3
	# Add attack actions
	addAttackActions choices, map
	# Add look/describe actions
	addDescribeActions choices

	return new ActionChoiceSet(choices)

global.resolveAction = (map, string) ->
	actionSet = createActionChoiceSet(map)
	[choices, parsedFully] = actionSet.possibleMatches string
	choiceDescs = []
	for choice in choices 
		choiceDescs.push(choice.describe())
	if choices.length == 0 or (not parsedFully and choiceDescs.length > 5)
		return "Could not understand action."
	# Show actions if not too many possibilities exist:
	if not parsedFully
		return "Could not understand action. Similar actions are:\n" + choiceDescs.join "\n"
	if choices.length == 1
		return choices[0].action
	return "Ambiguous action. Possibilities are: \n" + choiceDescs.join "\n"
