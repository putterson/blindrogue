class window.MapRoom
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

class window.MapDoor
    constructor: (x, y) ->
        @x = x
        @y = y

class window.MapSquare
    constructor: (char = '#', solid = true, wasSeen = false) ->
        @char = char
        @solid = solid
        @objects = []
        # Was the square ever seen?
        @wasSeen = wasSeen
    addObject: (obj) -> @objects.push obj
    removeObject: (obj) -> elemRemove @objects, obj

class window.Map
    # Create a map that is filled with nothing
    constructor: (w, h) ->
        @w = w
        @h = h
        @rooms = []
        @objects = []
        @grid = ((new MapSquare() for _ in [0 .. w-1]) for _ in [0 .. h - 1])
        @player = null
        @frame = 1

        console.log @grid.length

    withinRoom: (x,y) ->
        for room in @rooms
            if room.within(x,y)
                return true
        return false

    # Map query operators
    get: (x,y) -> @grid[y][x]
    isSolid: (x,y) -> 
        if x < 0 or x >= @w or y < 0 or y >= @h 
            return true
        @get(x,y).solid
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
    addObject: (obj) ->
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
        for object in @objects
            object.step()
        @frame++

    # Generate onto our map using rot.js 'Digger' algorithm
    generate: () ->
        rotMap = new ROT.Map.Digger(@w, @h)

        map = this
        rotMap.create (x,y,val) -> 
            sqr = map.get(x,y)
            if val == 0
                sqr.char = '.'
                sqr.solid = false
            else
                sqr.char = '#'
                sqr.solid = true

        for rotRoom in rotMap.getRooms()
            x1 = rotRoom.getLeft()
            y1 = rotRoom.getTop()
            x2 = rotRoom.getRight()
            y2 = rotRoom.getBottom()
            room = new MapRoom(x1,y1,x2,y2)
            rotRoom.getDoors (x,y) ->
                room.doors.push new MapDoor(x,y)
                map.grid[y][x].char = 'E'
            @rooms.push room

    # Note: console.log is node-js only!
    print: () ->
        console.log "FRAME #{@frame}"
        y = 0
        sep = ''
        for _ in [0..@w + 1]
            sep += '-'
        console.log sep
        for row in @grid
            row_str = '|'
            x = 0
            for sqr in row
                seen = @player.seen(x, y)
                char = ' '
                if seen or sqr.wasSeen
                    # First try to draw a solid object:
                    obj = @getSolidObject(x, y)
                    if obj == null
                        obj = @getTopObject(x, y)
                    if obj != null
                        char = obj.consoleRepr()
                    else
                        char = sqr.char
                    if not seen
                        char = clc.blackBright(char)
                row_str += char
                x += 1
            console.log row_str + '|'
            y += 1
        console.log sep

