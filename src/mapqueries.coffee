################################################################################
# Utility query functions for spatial queries involving objects.
################################################################################

global.objDiagSquaresNear = (obj) -> [
		[obj.x - 1, obj.y - 1]
		[obj.x + 1, obj.y - 1]
		[obj.x - 1, obj.y + 1]
		[obj.x + 1, obj.y + 1]
	]

global.objOrthoSquaresNear = (obj) -> [
		[obj.x - 1, obj.y]
		[obj.x + 1, obj.y]
		[obj.x, obj.y - 1]
		[obj.x, obj.y + 1]
	]

global.objSquaresNear = (obj) -> 
	objDiagSquaresNear(obj).concat(objOrthoSquaresNear(obj))

global.objApproxDirection = (obj1, obj2) -> approxDirection obj2.x-obj1.x, obj2.y-obj2.y

global.objNearby = (obj, type) ->
	for [x,y] in objSquaresNear(obj)
		for other in obj.map.getObjects(x, y)
			if other == type
				return other
			if typeof type == 'function' and other instanceof type
				return other
	return null

# Returns if an object is in a corner (eg walls left, up & up-left)
global.objIsInCorner = (obj) ->
	map = obj.map
	for [x,y] in objDiagSquaresNear(obj)
		if map.isSolid(x, y) and map.isSolid(obj.x, y) and map.isSolid(x, obj.y)
			return true
	return false

# Returns the next step towards the monster. Uses pathfinding. Nil if no path
global.objDirTowards = (obj1, obj2, usePlayerSight = false) ->
	map = obj1.map
	passable = (x,y) ->
		if (obj2.x == x and obj2.y == y) or (obj1.x == x and obj1.y == y) 
			return true # Exemption for target square
		return not map.isBlocked(x,y)
	playerPassable = (x,y) ->
		if (obj2.x == x and obj2.y == y) or (obj1.x == x and obj1.y == y) 
			return true # Exemption for target square
		if map.isSeen(x,y)
			return not map.isBlocked(x,y)
		else if map.wasSeen(x,y)
			return not map.isSolid(x,y)
		else 
			return true # Assume not solid, to encourage exploration
	astar = new ROT.Path.AStar(obj2.x, obj2.y, if usePlayerSight then playerPassable else passable)
	pathSquares = []
	astar.compute(obj1.x, obj1.y, (x, y) -> pathSquares.push [x,y])
	if pathSquares.length <= 1 
		return null
	[tx, ty] = pathSquares[1]
	return [tx - obj1.x, ty - obj1.y]

# Try all directions that include at least one non-zero component of our direction
global.objFindFreeDirection = (obj, dx, dy) ->
	# Test if a direction is free
	free = (testdx, testdy) -> 
		return not obj.map.isBlocked(obj.x + testdx, obj.y + testdy)
	if free(dx, dy) 
		return [dx, dy]
	if dx == 0
		if free(-1, dy) 
			return [-1, dy]
		if free(1, dy)
			return [1, dy]
	else if dy == 0
		if free(dx, 1)  
			return [dx,  1]
		if free(dx, -1) 
			return [dx, -1]
	else 
		if free(dx, 0)  
			return [dx,  0]
		if free(0, dy) 
			return [0, dy]
	return null
