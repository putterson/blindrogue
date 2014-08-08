pickMapData = (level) ->
    choices = []
    for mapdata in MAPDATA
        if level in mapdata.levels
            choices.push mapdata
    assert choices.length > 0, "No map data for #{level}!"
    return randChoose choices

PADDING = 1
global.generateMap = ({level}) ->
    {levels, w, h} = pickMapData level

    rotMap = new ROT.Map.Digger(w, h)
    map = new Map w + PADDING*2,h + PADDING*2
    map.level = level

    rotMap.create (x,y,val) -> 
        x += PADDING
        y += PADDING
        sqr = map.get(x,y)
        if val == 0
            sqr.char = '.'
            sqr.solid = false
        else
            sqr.char = '#'
            sqr.solid = true

    for rotRoom in rotMap.getRooms()
        x1 = rotRoom.getLeft() +  PADDING
        y1 = rotRoom.getTop() +  PADDING
        x2 = rotRoom.getRight() +  PADDING
        y2 = rotRoom.getBottom() +  PADDING
        room = new MapRoom(x1,y1,x2,y2)
        rotRoom.getDoors (x,y) ->
            x += PADDING
            y += PADDING
            room.doors.push new MapDoor(x,y)
            map.get(x,y).char = 'E'
        map.rooms.push room

    for _ in [1..2]
        [eX, eY] = map.randEmptySquare()
        map.addObject new MonsterObj(map, MONSTERS["Keukegen"], eX, eY)

    for _ in [1..1]
        [iX, iY] = map.randEmptySquare()
        itemName = randChoose ["Ale of Health", "Bō", "Amulet of Staffing"]
        map.addObject new ItemObj(map, ITEMS[itemName], iX, iY)

    for _ in [1..1]
        [eX, eY] = map.randEmptySquare()
        # Make downstaircase
        map.get(eX, eY).char = '<'

    for _ in [1..1]
        [eX, eY] = map.randEmptySquare()
        # Make upstaircase
        map.get(eX, eY).char = '>'


    return map