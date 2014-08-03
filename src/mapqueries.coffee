################################################################################
# Utility query functions for spatial queries involving objects.
################################################################################

window.objDiagSquaresNear = (obj) -> [
		[obj.x - 1, obj.y - 1]
		[obj.x + 1, obj.y - 1]
		[obj.x - 1, obj.y + 1]
		[obj.x + 1, obj.y + 1]
	]

window.objOrthoSquaresNear = (obj) -> [
		[obj.x - 1, obj.y]
		[obj.x + 1, obj.y]
		[obj.x, obj.y - 1]
		[obj.x, obj.y + 1]
	]

window.objSquaresNear = (obj) -> objDiagSquaresNear(obj).concat(objOrthoSquaresNear(obj))

window.objNearby = (obj, type) ->
	for [x,y] in objSquaresNear(obj)
		for other in obj.map.getObjects(x, y)
			if other instanceof type
				return other
	return null

# Returns if an object is in a corner (eg walls left, up & up-left)
window.objIsInCorner = (obj) ->
	map = obj.map
	for [x,y] in objDiagSquaresNear(obj)
		if map.isSolid(x, y) and map.isSolid(obj.x, y) and map.isSolid(x, obj.y)
			return true
	return false

# Returns the next step towards the monster. Uses pathfinding. Nil if no path
window.objDirTowards = (obj1, obj2, usePlayerSight = false) ->
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
			return false
	astar = new ROT.Path.AStar(obj2.x, obj2.y, if usePlayerSight then playerPassable else passable)
	pathSquares = []
	astar.compute(obj1.x, obj1.y, (x, y) -> pathSquares.push [x,y])
	if pathSquares.length <= 1 
		return null
	[tx, ty] = pathSquares[1]
	return [tx - obj1.x, ty - obj1.y]

