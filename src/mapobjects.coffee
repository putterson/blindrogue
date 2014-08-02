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

class window.MonsterObj extends BaseObj
    constructor: (map, char, x, y) ->
        super(map, char, x,y)
