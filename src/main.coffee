# Game =
#   display: null
#   map: {}
#   engine: null
#   player: null
#   init: ->
#     #@display = new ROT.Display()
#     #document.body.appendChild @display.getContainer()
#     @_generateMap()
#     scheduler = new ROT.Scheduler.Simple()
#     scheduler.add @player, true
#     @engine = new ROT.Engine(scheduler)
#     @engine.start()

#   _generateMap: ->
#     digger = new ROT.Map.Digger()
#     freeCells = []
#     digCallback = (x, y, value) ->
#       if value 
#           return
#       key = x + "," + y
#       @map[key] = "."
#       freeCells.push key

#     digger.create digCallback.bind(this)
#     @_generateBoxes freeCells
#     @_drawWholeMap()
#     @_createPlayer freeCells

#   _createPlayer: (freeCells) ->
#     index = Math.floor(ROT.RNG.getUniform() * freeCells.length)
#     key = freeCells.splice(index, 1)[0]
#     parts = key.split(",")
#     x = parseInt(parts[0])
#     y = parseInt(parts[1])
#     @player = new Player(x, y)

#   _generateBoxes: (freeCells) ->
#     i = 0
#     while i < 10
#       index = Math.floor(ROT.RNG.getUniform() * freeCells.length)
#       key = freeCells.splice(index, 1)[0]
#       @map[key] = "*"
#       i++

#   _drawWholeMap: ->
#     #for key of @map
#     #  parts = key.split(",")
#     #  x = parseInt(parts[0])
#     #  y = parseInt(parts[1])
#     #  @display.draw x, y, @map[key]

# Player = (x, y) ->
#   @_x = x
#   @_y = y
#   @_draw()

# Player::act = ->
#   Game.engine.lock()
#   # global.addEventListener "keydown", this

# Player::handleEvent = (e) ->
#   keyMap = {}
#   keyMap[38] = 0
#   keyMap[33] = 1
#   keyMap[39] = 2
#   keyMap[34] = 3
#   keyMap[40] = 4
#   keyMap[35] = 5
#   keyMap[37] = 6
#   keyMap[36] = 7
#   code = e.keyCode
    
#   # one of numpad directions? 
#   if !(code of keyMap)
#       return
    
#   # is there a free space? 
#   dir = ROT.DIRS[8][keyMap[code]]
#   newX = @_x + dir[0]
#   newY = @_y + dir[1]
#   newKey = newX + "," + newY
#   if !(newKey of Game.map)
#       return
#   Game.display.draw(@_x, @_y, Game.map[@_x + "," + @_y])
#   @_x = newX
#   @_y = newY
#   @_draw()
#   global.removeEventListener("keydown", this)
#   Game.engine.unlock()

# Player::_draw = ->
#   # Game.display.draw @_x, @_y, "@", "#ff0"

# Game.init()

map = new Map(40,40)

generateMap = () ->
    map.generate()

    [pX, pY] = map.randEmptySquare()
    player = new PlayerObj(map, '@', pX, pY)
    map.addObject player

    for _ in [1..10]
        [eX, eY] = map.randEmptySquare()
        map.addObject new MonsterObj(map, MONSTERS["Keukegen"], eX, eY)

    for _ in [1..10]
        [iX, iY] = map.randEmptySquare()
        itemName = randChoose ["Potion of Health", "Bō", "Amulet of Staffing"]
        map.addObject new ItemObj(map, ITEMS[itemName], iX, iY)

    map.player = player
    # Compute initial FOV:
    player.computeFov()

generateMap()
view = new ViewDescriber(map)

stepWithAction = (action) ->
    messages = []
    # If we have a valid action:
    player = map.player
    # Copy over the player action, for the step event
    player.action = action
    while true
        [canPerform, reasonIfCant] = action.canPerform(player)
        if not canPerform
            messages.push clc.red(reasonIfCant)
            break
        map.step()
        # Important: Check interruption status BEFORE clearing events!
        [isInterrupted, reasonIfInterrupted] = action.isInterrupted(player)
        for event in map.getAndResetEvents()
            messages.push(event.message)
        # Report anything new for this step
        messages = messages.concat view.step()
        if action.isComplete(player)
            break
        if isInterrupted
            messages.push clc.blackBright(reasonIfInterrupted)
            break
    # Reset the player action (make sure we don't accidentally use it again)
    player.action = null
    if not process.env.BLIND
        map.print()
    for m in messages
            console.report m

resolvePlayerAction = (answer) ->
    action = resolveAction(map, answer)
    # Did we encounter an error during parsing?
    if typeof action == 'string'
        if action == "describe"
            console.report view.describe().join("\n")
        else if action == "reveal"
            map.print()
        else
            console.report action
    else
        stepWithAction(action)
    # Set the callback so that we will read again in a 'loop'
    setReadLineCallback()

setReadLineCallback = () ->
    STDIN.question "What is your action? ", resolvePlayerAction

if not process.env.BLIND
    map.print()
for m in view.describe()
    console.report m

setReadLineCallback()