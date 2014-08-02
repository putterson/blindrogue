class window.MapRoom
    constructor: (x1, y1, x2, y2) ->
        @x1 = x1
        @y1 = y1
        @x2 = x2
        @y2 = y2

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
        @grid = ((new MapSquare(' ') for _ in [0 .. w-1]) for _ in [0 .. h - 1])
        console.log @grid.length

    # Generate onto our map using rot.js 'Digger' algorithm
    generate: () ->
        rotMap = new ROT.Map.Digger(@w, @h)
        for rotRoom in rotMap.getRooms()
            x1 = room.getLeft()
            y1 = room.getTop()
            x2 = room.getRight()
            y2 = room.getBottom()
            @rooms.push new MapRoom(x1,y1,x2,y2)

        grid = @grid
        rotMap.create (x,y,val) -> 
            if val == 0
                grid[y][x].char = ' '
            else
                grid[y][x].char = '.'
    # Note: node-js only!
    print: () ->
        for row in @grid
            row_str = ''
            for sqr in row
                row_str += sqr.char
            console.log row_str

#    @_generateBoxes freeCells
#    @_drawWholeMap()
#    @_createPlayer freeCells


