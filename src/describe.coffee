global.describeBlockingSquare = (map, x, y) ->
	if map.isSolid(x,y)
		return "There is a wall in the way!"
	obj = map.getSolidObject(x,y)
	return "The #{obj.getName()} is in the way!"
