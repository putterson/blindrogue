global.describeBlockingSquare = (map, x, y) ->
	if map.isSolid(x,y)
		return "There is a wall in the way!"
	obj = getSolidObject(x,y)
	return "The #{obj} is in the way!"
