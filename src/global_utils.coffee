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
        throw message

global.elemRemove = (array, elem) ->
	index = array.indexOf(elem)
	if index > -1
    	array.splice(index, 1)
