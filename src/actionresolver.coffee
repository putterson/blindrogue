# 'aggresive' means attacking or moving towards an enemy
aggresiveActionInterrupted = (obj) ->
    if obj.map.eventOccurred "PlayerWasAttacked"
        return [true, "You stop. You are being attacked!"]
    return [false]

# 'passive' means not attacking or moving towards an enemy
passiveMoveActionInterrupted = (obj) ->
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

class global.MoveAction
    constructor: (@nSteps, @dx, @dy, @wordsUsed) ->
    isInterrupted: (obj) -> passiveMoveActionInterrupted obj
    # No message attached because reason for isComplete should be 'obvious'
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

class global.MoveTowardsAction
    # Target can be a BaseObj inheritor, or simply an object with x & y defined.
    constructor: (@nSteps, @target, @isAggressiveAction) ->

    isInterrupted: (obj) ->
        if @isAggressiveAction
            return aggresiveActionInterrupted obj
        else
            return passiveMoveActionInterrupted obj
    isComplete: (obj) -> 
        if @nSteps <= 0 or (obj.x == @target.x and obj.y == @target.y)
            return true
        return (obj.solid and objNearby(obj, @target))
    onTarget: (obj) -> obj.x == @target.x and obj.y == @target.y
    canPerform: (obj) ->
        if @target.isRemoved
            return [false, "The #{@target.getName()} is not here anymore!"]
        if @onTarget obj
            return [true]
        dir = objDirTowards obj, @target, true # Use player sight
        if not dir
            return [false, "You have no route to the #{@target.getName()}!"]
        return [true]

    perform: (obj) ->
        @nSteps--
        [dx, dy] = objDirTowards obj, @target, true # Use player sight
        targetName = @target.getName()
        obj.map.events.push {type: "PlayerMove", message: "You move #{dirToCompassDir dx, dy} towards the #{targetName}."}
        obj.move(dx, dy)

class global.ItemPickupAction extends MoveTowardsAction
    constructor: (itemObject) ->
        super(10, itemObject, false)
        @itemPickedUp = false
    isComplete: (obj) -> @itemPickedUp
    perform: (obj) ->
        if @onTarget(obj)
            console.log "PICKUP"
            obj.getStats().addItem(@target.getItem())
            obj.map.events.push {type: "ItemPickup", message: "You pick up the #{@target.getName()}."}
            @target.remove()
            @itemPickedUp = true
            return
        return super(obj)

class global.UseItemAction
    constructor: (@item) ->
        @wasUsed = false

    isInterrupted: aggresiveActionInterrupted
    isComplete: () -> @wasUsed
    canPerform: (obj) -> return @item.canUse(obj.getStats())
    perform: (obj) ->
        @wasUsed = true
        obj.getStats().useItem(@item)

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
        if @target.isRemoved
            return [false, "The #{target.getName()} is already dead!"]
        if not objNearby obj, @target
            return [false, "You are too far from the enemy!"]
        return [true]

    perform: (obj) -> 
        obj.attack @target
        @didAttack = true

dirToWordCombos = (dx, dy) ->
    words = []
    # Straight up/down
    if dx == +0 and dy == -1 then return ["north",         "up"                   ]
    if dx == +0 and dy == +1 then return ["south",         "down"                 ]
    # Rightward
    if dx == +1 and dy == -1 then return ["north east", "up right",   "right up"  ]
    if dx == +1 and dy == 0  then return ["east",        "right"                  ]
    if dx == +1 and dy == +1 then return ["south east", "down right", "right down"]
    # Leftward
    if dx == -1 and dy == -1 then return ["north west", "up left",    "left up"   ]
    if dx == -1 and dy == 0  then return ["west",         "left"                  ]
    if dx == -1 and dy == +1 then return ["south west", "down left",  "left down" ]
    assert false, "Bad dx=#{dx} dy=#{dy}!"

dirToCompassDir = (dx, dy) -> 
    [bucket] = dirToWordCombos(dx, dy)
    return bucket

MOVE_WORDS = ["Move"]
ATTACK_WORDS = ["Attack", "Fight"]
ITEMGET_WORDS = ["Get", "Pickup"]
STEP_WORDS = ["Step"]
LOOK_WORDS = ["Look"]

DIRECTIONS = ["north", "north east", "east", "south east", "south", "south west", "west", "north west"]

makeObjectDirBuckets = (map, objs) ->
    # Holds objects found in each direction
    directionBuckets = {}
    for dir in DIRECTIONS
        directionBuckets[dir] = []
    # Place objects into buckets
    for obj in objs
        [dx,dy] = objApproxDirection(map.player, obj)
        # Take the first word (uses north etc instead of up/left etc)
        bucket = dirToCompassDir(dx, dy)
        directionBuckets[bucket].push(obj)
    return directionBuckets

# Monster actions are either attacking, or (m)oving (t)o a monster
addMonsterActions = (choices, map) ->
    # Place enemies into buckets, closest enemies first (due to seenObjects call).
    # 'directionBuckets' holds enemies found in each direction
    directionBuckets = makeObjectDirBuckets map, map.seenObjects(MonsterObj)
    # Create attack options from enemies seen
    for dir in DIRECTIONS
        i = 1
        for obj in directionBuckets[dir]
            attackName = map.player.getStats().getAttack().name
            targetName = obj.getName()
            lastWords = (targetName.split " ").concat(dir.split " ")
            lastWords.push i.toString()
            # TODO account for player range
            if objNearby map.player, obj
                for firstWord in ATTACK_WORDS
                    words = [firstWord].concat(lastWords)
                    choices.push new ActionChoice(words,  new AttackAction(obj), "#{words.join " "}:\n Strike the #{targetName} with your #{attackName}.")
            # Always have a move-to action, even if in range. At the worst you'll be informed that you're already nearby.
            words = ["Move", "to"].concat(lastWords)
            choices.push new ActionChoice(words,  new MoveTowardsAction(3, obj, true), "#{words.join " "}:\n Move towards the #{targetName}.")
            i++

addDoorActions = (choices, map) ->
    # Holds doors found in each direction
    seenDoors = []
    for [x,y] in map.player.seenSqrs
        # Is it a door?
        if map.get(x,y).char == 'E' then seenDoors.push {x: x,y: y, solid: false}
    # Place doors into buckets
    # 'directionBuckets' holds doors found in each direction
    directionBuckets = makeObjectDirBuckets map, seenDoors
    for dir in DIRECTIONS
        i = 1
        for doorObj in directionBuckets[dir]
            for prefix in ["Door", "Move to door"]
                doorObj.getName = () -> "#{dir} door"
                words = "#{prefix} #{dir} #{i}".split(" ")
                choices.push new ActionChoice(words,  new MoveTowardsAction(3, doorObj, false), "#{words.join " "}:\n Move towards the door.")
            i++ 

addMoveActions = (choices, firstWords, nSteps) ->
    for firstWord in firstWords
        for dx in [-1 .. +1] 
            for dy in [-1 .. +1]
                if dx != 0 or dy != 0
                    for dirWords in dirToWordCombos dx, dy
                        words = [firstWord].concat(dirWords.split " ")
                        choices.push new ActionChoice(words, new MoveAction(nSteps, dx, dy, dirWords))

addLookActions = (choices) ->
    for firstWord in LOOK_WORDS
        choices.push new ActionChoice([firstWord], "describe", "#{firstWord}\n Look around you.")
    choices.push new ActionChoice(["reveal"], "reveal", "Reveal\n Reveals the map for you, Mr. Cheater McCheaterson.")

addPickupItemActions = (choices, map) ->
    # Holds items found in each direction
    directionBuckets = makeObjectDirBuckets map, map.seenObjects ItemObj
    for dir in DIRECTIONS
        i = 1
        for itemObj in directionBuckets[dir]
            for firstWord in ITEMGET_WORDS
                words = "#{firstWord} #{itemObj.getName()} #{dir} #{i}".split(" ")
                choices.push new ActionChoice words, new ItemPickupAction(itemObj)

addUseItemActions = (choices, map) ->
    stats = map.player.getStats()
    for item in stats.getItems()
        console.log "ITEM"
        command = "Use " + item.getName()
        choices.push new ActionChoice command.split(" "), 
            new UseItemAction(item),
            "#{command}:\n Use the #{item.getName()}: #{item.getDescription()}"

createActionChoiceSet = (map) ->
    choices = []
    # Add step actions
    addMoveActions choices, STEP_WORDS, 1 
    # Add move actions
    addMoveActions choices, MOVE_WORDS, 3
    # Add attack actions
    addMonsterActions choices, map
    # Add look/describe actions
    addLookActions choices
    # Move-to door actions
    addDoorActions choices, map
    # Add pickup item actions
    addUseItemActions choices, map
    # Add use item actions
    addPickupItemActions choices, map

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
