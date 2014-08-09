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
    constructor: (@nSteps, @dx, @dy) ->
        @path = null
        @pathI = 0
    isInterrupted: (obj) -> passiveMoveActionInterrupted obj
    # No message attached because reason for isComplete should be 'obvious'
    isComplete: (obj) -> (@nSteps <= 0)
    canPerform: (obj) ->
        # Rely on canPerform being called before every perform
        if not @path? then @path = objPathInDirection(obj, @dx, @dy, @nSteps)
        if @path? 
            dir = @path[@pathI]
            if dir? 
                dir = objFindFreeDirection(obj, dir[0], dir[1])
                if dir? 
                    return [true]
        return [false, describeBlockingSquare(obj.map, obj.x + @dx, obj.y + @dy)]

    perform: (obj) ->
        @nSteps--
        [dx, dy] = @path[@pathI++]
        [dx, dy] = objFindFreeDirection(obj, dx, dy)
        obj.map.events.push {type: "PlayerMove", message: "You move #{dirToCompassDir dx, dy}."}
        obj.move(dx, dy)

class global.ExploreAction
    constructor: (@nSteps) ->
        @path = null
        @pathI = 0
    isInterrupted: (obj) -> passiveMoveActionInterrupted obj
    # No message attached because reason for isComplete should be 'obvious'
    isComplete: (obj) -> (@nSteps <= 0)
    canPerform: (obj) ->
        # Rely on canPerform being called before every perform
        if not @path? or not @path[@pathI]? then @path = objPathForMapExplore(obj, @nSteps)
        if @path? 
            dir = @path[@pathI]
            if dir? 
                newDir = objFindFreeDirection(obj, dir[0], dir[1])
                if newDir? 
                    return [true]
                else
                    return [false, describeBlockingSquare(obj.map, obj.x + dir[0], obj.y + dir[1])]
        return [false, "There is nothing unexplored nearby."]

    perform: (obj) ->
        @nSteps--
        [dx, dy] = @path[@pathI++]
        [dx, dy] = objFindFreeDirection(obj, dx, dy)
        obj.map.events.push {type: "PlayerMove", message: "You move #{dirToCompassDir dx, dy}."}
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

class global.MoveToStairsAction extends MoveTowardsAction
    constructor: (stairsObject, downStairs, useStairs) ->
        super(10, stairsObject, false)
        @stairsEntered = false
        @downStairs = downStairs
        @useStairs = useStairs
    isComplete: (obj) -> 
        if not @useStairs
            return @onTarget(obj) 
        return @stairsEntered
    canPerform: (obj) ->
        if not @useStairs and @onTarget(obj)
            return [false, "You are already at the stairs!"]
        return super(obj)
    perform: (obj) ->
        if @onTarget(obj)
            level = obj.map.level 
            if level == 1 and not @downStairs
                obj.map.events.push {type: "CantGoUp", message: "You are not ready to leave Dōkutsu. You must return a hero."}
            else
                level = if @downStairs then (level + 1) else (level - 1)
                # Move to the new map:
                obj.map.removeObject(obj)
                newMap = getGameMap {level}
                # Position the player to the staircase in the new map
                [[obj.x, obj.y]] = if @downStairs then newMap.getUpStairCases() else newMap.getDownStairCases()
                obj.map = newMap
                obj.map.addObject(obj)
                obj.map.events.push {type: "UseStairs", message: "You use the #{@target.getName()}."}
            @stairsEntered = true
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
ATTACK_WORDS = ["Attack"]
ITEMGET_WORDS = ["Get"]
STEP_WORDS = ["Take step"]
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
            for firstWord in ATTACK_WORDS
                words = [firstWord].concat(lastWords)

                if objNearby map.player, obj
                    action = new AttackAction(obj)
                    desc = "#{words.join " "}:\n Strike the #{targetName} with your #{attackName}."
                else
                    # Otherwise, move one towards the enemy
                    action = new MoveTowardsAction(1, obj)
                    if not action.canPerform(map.player)
                        break
                    desc = "#{words.join " "}:\n Move in range of the #{targetName}, so that you can strike with your #{attackName}."
                choices.push new ActionChoice(words, action, desc)
            # Always have a move-to action, even if in range. At the worst you'll be informed that you're already nearby.
            words = ["Move", "to"].concat(lastWords)
            choices.push new ActionChoice(words,  new MoveTowardsAction(3, obj, true), "#{words.join " "}:\n Move towards the #{targetName}.")
            i++

addDoorActions = (choices, map) ->
    # Holds doors found in each direction
    seenDoors = []
    for [x,y] in map.player.seenSqrs
        if map.player.x == x and map.player.y == y
            continue # Don't include actions for doors directly beneath us
        # Is it a door?
        if map.get(x,y).char == 'E' then seenDoors.push {x: x,y: y, solid: false}
    # Place doors into buckets
    # 'directionBuckets' holds doors found in each direction
    directionBuckets = makeObjectDirBuckets map, seenDoors
    for dir in DIRECTIONS
        i = 1
        for doorObj in directionBuckets[dir]
            for prefix in ["Door", "Move to door"]
                doorObj.name = "#{dir} door"
                doorObj.getName = () -> @name
                words = "#{prefix} #{dir} #{i}".split(" ")
                choices.push new ActionChoice(words,  new MoveTowardsAction(3, doorObj, false), "#{words.join " "}:\n Move towards the door.")
            i++ 

addMoveActions = (choices, firstWords, nSteps) ->
    for firstWord in firstWords
        for dx in [-1 .. +1] 
            for dy in [-1 .. +1]
                if dx != 0 or dy != 0
                    for dirWords in dirToWordCombos dx, dy
                        words = "#{firstWord} #{dirWords}".split " "
                        choices.push new ActionChoice(words, new MoveAction(nSteps, dx, dy))

addLookActions = (choices) ->
    for firstWord in LOOK_WORDS
        choices.push new ActionChoice([firstWord], "describe", "#{firstWord}\n Look around you.")
    choices.push new ActionChoice(["reveal"], "reveal", "Reveal\n Reveals the map for you, Mr. Cheater McCheaterson.")
    choices.push new ActionChoice(["fullreveal"], "fullreveal", "FullReveal\n Reveals the map, including unexplored areas, for you, Mr. Cheater McCheaterson.")

addPickupItemActions = (choices, map) ->
    # Holds items found in each direction
    directionBuckets = makeObjectDirBuckets map, map.seenObjects ItemObj
    for dir in DIRECTIONS
        i = 1
        for itemObj in directionBuckets[dir]
            for firstWord in ITEMGET_WORDS
                words = "#{firstWord} #{itemObj.getName()} #{dir} #{i}".split(" ")
                choices.push new ActionChoice words, new ItemPickupAction(itemObj)
            i++

addUseItemActions = (choices, map) ->
    stats = map.player.getStats()
    for item in stats.getItems()
        command = "Use " + item.getName()
        choices.push new ActionChoice command.split(" "), 
            new UseItemAction(item),
            "#{command}:\n Use the #{item.getName()}: #{item.getDescription()}"

addExploreActions = (choices) ->
    choices.push new ActionChoice "Explore", 
        new ExploreAction(10),
        "Explore:\n Seek out unexplored areas."

addStairsActions = (choices, map) ->
    # Holds doors found in each direction
    seenStairs = []
    for [x,y] in map.getUpStairCases() .concat map.getDownStairCases()
        if not map.wasSeen(x,y)
            continue
        # Is it a downstaircase?
        {char} = map.get(x,y)
        if char == '>' then seenStairs.push {x: x,y: y, solid: false, isDown: false, dir: "up", getName: () -> "stairs #{@dir}"}
        if char == '<' then seenStairs.push {x: x,y: y, solid: false, isDown: true, dir: "down", getName: () -> "stairs #{@dir}"}

    # Holds stairs found in each direction
    directionBuckets = makeObjectDirBuckets map, seenStairs
    for dir in DIRECTIONS
        i = 1
        for doorObj in directionBuckets[dir]
            for [prefix, useStairs, desc] in [["Use stairs", true, "Go towards, and use, the staircase"], ["Move to stairs", false, "Go towards the staircase"]]
                words = "#{prefix} #{doorObj.dir} #{dir} #{i}".split(" ")
                choices.push new ActionChoice words, new MoveToStairsAction(doorObj, doorObj.isDown, useStairs), "#{prefix} #{doorObj.dir}:\n #{desc}."
            i++

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
    # Exploring the map
    addExploreActions choices
    # Move-to door actions
    addDoorActions choices, map
    # Stairs actions
    addStairsActions choices, map
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
    # Does it end in a '?'
    if string.indexOf('?') == string.length - 1 
        # Show possible actions:
        return "Possibile matches: \n" + choiceDescs.join "\n"
    if choices.length == 1
        choices[0].action.description = choices[0].describe()
        return choices[0].action
    return "Ambiguous action. Possibilities are: \n" + choiceDescs.join "\n"
