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
