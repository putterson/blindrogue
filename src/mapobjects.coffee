class global.BaseObj
    constructor: (map, char, x, y) ->
        @map = map
        # For debugging and replaying
        @char = char
        @x = x
        @y = y
        @isRemoved = false
    solid: false
    remove: () ->
        @map.get(@x, @y).removeObject this
        @isRemoved = true
    move: (dx, dy) ->
        @map.get(@x, @y).removeObject this
        @x += dx
        @y += dy
        @map.get(@x, @y).addObject this
    distanceTo: (x, y) ->
        dx = @x - x
        dy = @y - y
        return Math.sqrt(dx*dx + dy*dy)
    consoleRepr: () -> @char
    step: () ->
        # Nothing by default

class global.CombatObj extends BaseObj
    solid: true
    constructor: (map, @rawStats, char, x, y) ->
        super(map, char, x,y)
    getStats: () -> new Stats(@, @rawStats)

class global.PlayerObj extends CombatObj
    constructor: (map, char, x, y) ->
        super(map, makeStatsFromData(PLAYER_START_STATS), char, x,y)
        # Create the PreciseShadowcasting
        @fov = new ROT.FOV.PreciseShadowcasting (x, y) ->
            return not map.isSolid(x,y)
        @visionSqrs = 4
        @seenSqrs = []
        @action = null

    getName: () -> "ludderson"
    # Used at the start of a sentence
    wrapRegularVerb: (verb) -> "You #{verb}"
    step: () ->
        assert (not @action.isComplete(@)), "Already completed the action we have queued for this step!"
        assert @action.canPerform(@)[0], "Cannot perform the action e have queued for this step!"
        @action.perform(@)
        @computeFov()

    seen: (x,y) ->
        for [sx,sy] in @seenSqrs
            if sx == x and sy == y
                return true
        return false
    attack: (obj) ->
        description = @getStats().useAttack(obj.getStats())
        @map.events.push {type: "EnemyWasAttacked", message: description}
    computeFov: () ->
        @seenSqrs = []
        p = this
        @fov.compute @x, @y, @visionSqrs, (x,y,r,vis) ->
            if vis > 0
                p.map.get(x,y).wasSeen = true
                p.seenSqrs.push [x,y]

class global.MonsterObj extends CombatObj
    constructor: (map, @monsterType, x, y) ->
        super(map, makeStatsFromData(@monsterType), @monsterType.char, x,y)
        @chasingPlayer = false
        # How long to chase without sight before giving up?
        @chasingTimeout = 0

    getName: () -> @monsterType.name
    wrapRegularVerb: (verb) -> "The #{@getName()} #{verb}s"
    step: () -> 
        # Chasing state machine:
        if --@chasingTimeout <= 0
            @chasingPlayer = false
            @chasingTimeout  = 0
        if @map.isSeen(@x, @y)
            @chasingPlayer = true
            # How long to chase without sight before giving up?
            @chasingTimeout = 3
        # Check if the player is close enough to be attacked:
        player = objNearby @, PlayerObj
        if player != null
            description = @getStats().useAttack(player.getStats())
            @map.events.push {type: "PlayerWasAttacked", message: description}
        else if @chasingPlayer
            # Otherwise move towards player IF chasing player
            dir = objDirTowards @, @map.player
            if dir != null
                @move dir[0], dir[1]

    consoleRepr: () -> clc.redBright(@char)
    # Used at the start of a sentence
    getNameReference: () -> "The " + @getName()

class global.ItemObj extends BaseObj
    constructor: (map, @itemType, x, y) ->
        super(map, @itemType.char, x,y)
        @wasSeen = false
    step: () -> 
        if not @wasSeen and @map.isSeen @x, @y
            @wasSeen = true
    getName: () -> @itemType.name
    consoleRepr: () -> clc.blueBright(@char)