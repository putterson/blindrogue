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

global.objApproxDirection = (obj1, obj2) -> 
	return approxDirection obj2.x-obj1.x, obj2.y-obj1.y

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
		# assert((typeof x == 'number') and (typeof y == 'number') and not isNaN(x) and not isNaN(y))
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

global.objPathInDirection = (obj, dirX, dirY, lookAhead) ->
	map = obj.map
	minX = Math.max(obj.x - lookAhead, 0)
	maxX = Math.min(obj.x + lookAhead, map.w - 1)
	minY = Math.max(obj.y - lookAhead, 0)
	maxY = Math.min(obj.y + lookAhead, map.h - 1)
	# Populate the grid:
	grid = []
	for y in [minY..maxY]
		row = []
		for x in [minX..maxX]
			row.push {x, y, visited: false, open: false, distance: 1000, originNode: null, solid: map.wasSeen(x,y) and map.isSolid(x,y)}
		grid.push row

	openNodes = []
	visitNode = (originNode, x,y, distance) ->
		if originNode? and originNode.x == x and originNode.y == y
			return
		# Check bounds
		if x < minX or y < minY or x > maxX or y > maxY
			return
		node = grid[y - minY][x - minX]
		if not node.solid and (not node.visited or node.distance >= distance)
			# Don't do much if same distance, but might be 'more orthogonal' origin node
			if node.distance == distance
				if (node.x == originNode.x) or (node.y == originNode.y)
					node.originNode = originNode
				# Don't need to do the rest, return.
				return
			node.distance = distance
			node.visited = true
			if not node.open
				node.open = true
				openNodes.push node
			node.originNode = originNode
	visitNode(null, obj.x, obj.y, 0)
	# Solve all paths
	while openNodes.length > 0
		minDist = 1000
		minNode = null
		for node in openNodes
			if node.distance < minDist
				minDist = node.distance
				minNode = node
		for dy in [-1..1]
			for dx in [-1..1] 
				visitNode(node, node.x + dx, node.y + dy, node.distance + 1)
		elemRemove(openNodes, node)
		node.open = false
	# Find point that maximizes distance along the direction
	maxScore = 0
	maxNodes = []
	for row in grid
		for node in row when node.visited
			dX = (node.x - obj.x)
			dY = (node.y - obj.y)
			score = dX * dirX + dY * dirY
			# Penalize for moving in wrong dimension, just a bit
			if dirX == 0 then score -= Math.abs(dX) / 100
			if dirY == 0 then score -= Math.abs(dY) / 100
			console.log "node #{node.x - obj.x}, #{node.y - obj.y}, #{score}, #{maxScore}, #{maxNodes.length}"
			if score == maxScore
				maxNodes.push node
			else if score > maxScore
				maxScore = score
				maxNodes = [node]

	# console.log "maxNode #{maxNode.x - obj.x}, #{maxNode.y - obj.y}, #{maxScore}"
	if maxScore == 0 or maxNodes.length == 0
		return null

	# Back-track to first square moved to
	node = randChoose maxNodes
	path = []
	while true # Recreate the path
		{originNode} = node
		# Fully retraced path?
		if originNode == null
			break
		path.push [node.x - originNode.x, node.y - originNode.y]
		node = originNode
	path.reverse()
	return path

# global.objFreePathInDirection = (obj, dirX, dirY, lookAhead) ->
# 	dir = objPathInDirection obj, dirX, dirY, lookAhead
# 	if dir == null
# 		return null
# 	return objFindFreeDirection obj, dir[0], dir[1]
