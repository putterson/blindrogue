class global.MapRoom
    within: (x,y) ->
        if x < @x1 or x > @x2
            return false
        if y < @y1 or y > @y2
            return false
        return true

    constructor: (x1, y1, x2, y2) ->
        @x1 = x1
        @y1 = y1
        @x2 = x2
        @y2 = y2
        @doors = []

    size: () -> [
        (@x2 - @x1 + 1)
        (@y2 - @y1 + 1)
    ]

class global.MapDoor
    constructor: (x, y) ->
        @x = x
        @y = y

class global.MapSquare
    constructor: (char = '#', solid = true, wasSeen = false) ->
        @char = char
        @solid = solid
        @objects = []
        # Was the square ever seen?
        @wasSeen = wasSeen
    addObject: (obj) -> @objects.push obj
    removeObject: (obj) -> elemRemove @objects, obj

class global.Map
    # Create a map that is filled with nothing
    constructor: (w, h) ->
        @w = w
        @h = h
        @rooms = []
        @objects = []
        @grid = ((new MapSquare() for _ in [0 .. w-1]) for _ in [0 .. h - 1])
        @player = null
        @frame = 1
        @events = []

    getOfType: (char) ->
        ret = []
        for y in [0...@h-1]
            for x in [0...@w-1]
                if @get(x,y).char == char then ret.push [x,y]
        return ret

    getUpStairCases: () -> @getOfType ">"
    getDownStairCases: () -> @getOfType "<"

    # Did an event occur last step?
    eventOccurred: (checkType) ->
        for {type} in @events
            if type == checkType then return true
        return false

    getAndResetEvents: () ->
        oldEvents = @events
        @events = []
        return oldEvents

    withinRoom: (x,y) ->
        for room in @rooms
            if room.within(x,y)
                return true
        return false

    # Map query operators
    get: (x,y) -> @grid[y][x]
    wasSeen: (x,y) -> 
        if x < 0 or x >= @w or y < 0 or y >= @h 
            return false
        @get(x,y).wasSeen
    isSeen: (x,y) -> 
        for [sx, sy] in @player.seenSqrs
            if sx == x and sy == y
                return true
        return false

    # Seen objects of a certain type, sorted by proximity to player
    seenObjects: (type) ->
        {x: px, y: py} = @player
        seen = []
        for obj in @objects
            if obj instanceof type and @isSeen(obj.x, obj.y)
                seen.push obj
        seen.sort (a,b) -> 
            return a.distanceTo(px, py) - b.distanceTo(px, py) 
        return seen
    isSolid: (x,y) -> 
        if x < 0 or x >= @w or y < 0 or y >= @h 
            return true
        @get(x,y).solid
    objectTypeSeen: (type) ->
        for obj in @objects
            if obj instanceof type and @isSeen(obj.x, obj.y)
                return true
        return false
    getObjects: (x,y) -> @get(x,y).objects
    # Returns 'null' if no solid object exists
    getSolidObject: (x, y) ->
        for obj in @getObjects(x,y)
            if obj.solid
                return obj
        return null

    # For purposes of drawing mainly
    getTopObject: (x, y) ->
        objs = @getObjects(x,y)
        len = objs.length
        if len == 0
            return null
        return objs[len - 1]

    isBlocked: (x,y) -> @get(x,y).solid or (@getSolidObject(x,y) != null)

    # Object operators
    moveObject: (obj, dx, dy) ->
        @get(obj.x, obj.y).removeObject obj
        obj.x += dx
        obj.y += dy
        @get(obj.x, obj.y).addObject obj
    addObject: (obj) ->
        obj.isRemoved = false
        @get(obj.x, obj.y).addObject obj
        @objects.push obj
    removeObject: (obj) ->
        @get(obj.x, obj.y).removeObject obj
        elemRemove @objects, obj

    # Generation helpers
    randEmptySquare: () ->
        # Try 10000 times:
        for _ in [1..10000]
            x = randInt(0, @w)
            y = randInt(0, @h)
            if not @isBlocked x,y
                return [x,y]
        return null

    step: () ->
        # Ensure player goes first (otherwise action may not reflect information reported to player)
        @player.step()
        if @player.map != @
            @frame++
            return # Player has switched maps!
        safeCopy = (obj for obj in @objects)
        for object in safeCopy
            if object.isRemoved
                continue
            # Ensure player does not go twice
            if not (object instanceof PlayerObj)
                object.step()
        @frame++

    # Note: console.report is node-js only!
    print: (assumeSeen = false) ->
        console.report "FRAME #{@frame}"
        y = 0
        sep = ''
        for _ in [0..@w + 1]
            sep += '-'
        console.report sep
        for row in @grid
            row_str = '|'
            x = 0
            for sqr in row
                seen = assumeSeen or @player.seen(x, y)
                char = ' '
                if seen or sqr.wasSeen
                    # First try to draw a solid object:
                    obj = @getSolidObject(x, y)
                    if obj == null
                        obj = @getTopObject(x, y)
                    if seen and obj != null
                        char = obj.consoleRepr()
                    else
                        char = sqr.char

                    if char == '>' or char == '<'
                        char = if seen then clc.greenBright char else clc.green char 
                    else if not seen
                        char = clc.blackBright(char)
                row_str += char
                x += 1
            console.report row_str + '|'
            y += 1
        console.report sep

