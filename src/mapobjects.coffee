class window.BaseObj
    constructor: (map, char, x, y) ->
        @map = map
        # For debugging and replaying
        @char = char
        @x = x
        @y = y
    step: () ->
        # Nothing by default

class window.PlayerObj extends BaseObj
    constructor: (map, char, x, y) ->
        super(map, char, x,y)
        # Create the PreciseShadowcasting
        @fov = new ROT.FOV.PreciseShadowcasting (x, y) ->
            return not map.isSolid(x,y)
        @visionSqrs = 7
        @seenSqrs = []

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
                p.seenSqrs.push {x,y}

class window.MonsterObj extends BaseObj
    constructor: (map, char, x, y) ->
        super(map, char, x,y)
