# Global utilties for convenience

global.randInt = (min, max) -> 
	r = max - min
	return Math.floor(ROT.RNG.getUniform() * r) + min

global.randChance = (chance) -> 
	return (ROT.RNG.getUniform() < chance)

global.randChoose = (choices) -> 
	choice = randInt(0, choices.length)
	return choices[choice]

global.assert = (condition, message = "Assertion failed") ->
    if not condition
        throw new Error(message)

global.elemRemove = (array, elem) ->
	index = array.indexOf(elem)
	if index > -1
    	array.splice(index, 1)

# Just in case we're IE < 9 for some reason:
if not String.prototype.trim
	String.prototype.trim = () -> 
		return @replace /^\s+|\s+$/g, ""

# For approxDirection
_closeToDegree = (d1, d2) ->
	diff = d1 - d2
	if Math.abs(diff % 360) <= 22.5 or 360 - Math.abs(diff % 360) <= 22.5
		return true
	return false

global.approxDirection = (dx, dy) ->
	degree = Math.atan2(dx, dy)
	if _closeToDegree degree, 0
		return [0,1]
	if _closeToDegree degree, 45
		return [1,1]
	if _closeToDegree degree, 90
		return [1,0]
	if _closeToDegree degree, 135
		return [1,-1]
	if _closeToDegree degree, 180
		return [0,-1]
	if _closeToDegree degree, -45
		return [-1,1]
	if _closeToDegree degree, -90
		return [-1,0]
	if _closeToDegree degree, -135
		return [-1,-1]
	return [0,0]
