# Place for flavour text. Try to consolidate as much as feasible here.


global.describeIntroduction = () ->
	str = clc.redBright "You have disgraced your family's honour.\n"
	str += clc.redBright "You have brought much shame.\n"
	str += clc.redBright "But now the deadly Waira of Dōkutsu mountain eats children in your village.\n"
	str += clc.green "Enter Dōkutsu, vanquish the Waira, be the hero!"
	return str

global.describeBlockingSquare = (map, x, y) ->
	if map.isSolid(x,y)
		return "There is a wall in the way!"
	obj = map.getSolidObject(x,y)
	return "The #{obj.getName()} is in the way!"
