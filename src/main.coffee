################################################################################
# Executing this file runs the game. Relies on all other files being executed
# already.
################################################################################
"use strict";

# Predeclare 'global' state. (Local to this file)
# Initialized in main()
[map, view] = [null,null]

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
        itemName = randChoose ["Ale of Health", "Bō", "Amulet of Staffing"]
        map.addObject new ItemObj(map, ITEMS[itemName], iX, iY)

    map.player = player
    # Compute initial FOV:
    player.computeFov()

# Progresses the game world in response to a player action.
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

describeMap = () ->  console.report(view.describe().join("\n"))

# Progresses the game world in response to a (yet unparsed) player action.
# For actions such as 'describe' however, no time passes.
stepWithAnswer = (answer) ->
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
    resetStepEvent()

# Set-up for 'blocking' readline. We progress our game world in response to a read-line event.
STDIO = require('readline').createInterface {input: process.stdin, output: process.stdout}
resetStepEvent = () ->
    STDIO.question "What is your action? ", stepWithAnswer

# The main function.
main = () ->
    map = new Map(40,40)
    generateMap()
    view = new ViewDescriber(map)
    if not process.env.BLIND
        map.print()
    describeMap()

    resetStepEvent()

main()