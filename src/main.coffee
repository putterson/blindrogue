################################################################################
# Executing this file runs the game. Relies on all other files being executed
# already.
################################################################################
"use strict";

# Predeclare 'global' state. (Local to this file)
# Initialized in main()
[map, view, player] = [null,null,null]

spawnPlayer = (map) ->
    [[pX, pY]] = map.getUpStairCases()
    player = new PlayerObj(map, '@', pX, pY)
    map.addObject player
    # Compute initial FOV:
    player.computeFov()
    return player

# Progresses the game world in response to a player action.
stepWithAction = (action) ->
    if action.isComplete(player)
        # Assume it is a move-towards type of action!
        console.report "You are already nearby."
        return
    messages = []
    # If we have a valid action:
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
        map = player.map # Account for any changes in map
        # Report anything new for this step
        messages = messages.concat view.step()
        if action.isComplete(player)
            break
        if isInterrupted
            messages.push clc.blackBright(reasonIfInterrupted)
            break
    # Reset the player action (make sure we don't accidentally use it again)
    player.action = null
    # Clear the screen:
    process.stdout.write '\u001B[2J\u001B[0;0f'
    if not process.env.BLIND?
        map.print(false, process.env.SEMIBLIND?)
    # console.report clc.blackBright "(Action: #{action.description.split})"
    console.report describePlayerStats(player.getStats())
    console.report "Floor #{map.level} is #{parseInt map.percentExplored()*100}% explored."
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
        else if action == "reveal" or action == "fullreveal"
            map.print(action == "fullreveal") # Print unexplored areas?
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

mapsCached = {}
global.getGameMap = ({level}) -> 
    if not mapsCached[level]? 
        mapsCached[level] = generateMap {level}
    map = mapsCached[level]
    if not player?
        player = spawnPlayer map
    map.player = player
    return mapsCached[level]

# The main function.
main = () ->
    map = getGameMap {level: 1}
    console.report describeIntroduction()
    console.report "... "
    continueF = (unused) ->
        view = new ViewDescriber(map)
        if not process.env.BLIND?
            map.print(false, process.env.SEMIBLIND?)
        console.report(clc.magenta "You enter Dōkutsu, convinced you must return a hero or not at all.")
        describeMap()
        resetStepEvent()
    setTimeout continueF, 500

main()
