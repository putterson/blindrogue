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
	if obj == null
		#TODO Hack
		return "There is no good way to advance in that direction."
	return "The #{obj.getName()} is in the way!"


describeHp = ({hp, maxHp}) ->
	p = (hp/maxHp)
	if p < 0.1
		return clc.redBright "You are very low on health."
	if p < 0.25
		return clc.red "You are quite low on health."
	if p < 0.45
		return clc.red "You are low on health."
	if p < 0.75
		return clc.yellow "You have a moderate amount of health."
	if p < 1.00
		return clc.green "You have a great amount of health."
	return clc.greenBright "You are in perfect condition."

# Wee, coffeescript
describeAttack = ({attack: {name}}) -> clc.blackBright "You are wielding your #{name}."

global.describePlayerStats = ({derived}) ->
	# Wee, coffeescript
	return "#{describeHp derived}\n#{describeAttack derived}"