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
    constructor: (char) ->
        @char = char

class window.Map
    # Create a map that is filled with nothing
    constructor: (w, h) ->
        @w = w
        @h = h
        @rooms = []
        @doors = []
        @grid = ((new MapSquare(' ') for _ in [0 .. w-1]) for _ in [0 .. h - 1])
        console.log @grid.length

    within_room: (x,y) ->
        for room in @rooms
            if room.within(x,y)
                return true
        return false

    # Generate onto our map using rot.js 'Digger' algorithm
    generate: () ->
        rotMap = new ROT.Map.Digger(@w, @h)

        map = this
        rotMap.create (x,y,val) -> 
            if val == 1
                map.grid[y][x].char = '.'
            else
                map.grid[y][x].char = ' '



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

    # Note: node-js only!
    print: () ->
        for row in @grid
            row_str = ''
            for sqr in row
                row_str += sqr.char
            console.log row_str


