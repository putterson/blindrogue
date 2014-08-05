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
