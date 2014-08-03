class window.BaseObj
    constructor: (map, char, x, y) ->
        @map = map
        # For debugging and replaying
        @char = char
        @x = x
        @y = y
    solid: false
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

class window.CombatObj extends BaseObj
    solid: true
    constructor: (map, @rawStats, char, x, y) ->
        super(map, char, x,y)
    getStats: () -> new Stats(@, @rawStats)

class window.PlayerObj extends CombatObj
    constructor: (map, char, x, y) ->
        super(map, makeStatsFromData(PLAYER_START_STATS), char, x,y)
        # Create the PreciseShadowcasting
        @fov = new ROT.FOV.PreciseShadowcasting (x, y) ->
            return not map.isSolid(x,y)
        @visionSqrs = 7
        @seenSqrs = []
        @action = null

    getName: () -> "ludderson"
    # Used at the start of a sentence
    wrapRegularVerb: (verb) -> "You #{verb}"
    step: () ->
        @action.perform(@)
        @computeFov()

    seen: (x,y) ->
        for [sx,sy] in @seenSqrs
            if sx == x and sy == y
                return true
        return false
    computeFov: () ->
        @seenSqrs = []
        p = this
        @fov.compute @x, @y, @visionSqrs, (x,y,r,vis) ->
            if vis > 0
                p.map.get(x,y).wasSeen = true
                p.seenSqrs.push [x,y]

class window.MonsterObj extends CombatObj
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
            @map.events.push description
        else if @chasingPlayer
            # Otherwise move towards player IF chasing player
            dir = objDirTowards @, @map.player
            if dir != null
                @move dir[0], dir[1]

    consoleRepr: () -> clc.redBright(@char)
    # Used at the start of a sentence
    getNameReference: () -> "The " + @getName()

class window.ItemObj extends BaseObj
    constructor: (map, @itemType, x, y) ->
        super(map, @itemType.char, x,y)

    consoleRepr: () -> clc.blueBright(@char)