# Global utilties for convenience

window.randInt = (min, max) -> 
	r = max - min
	return Math.floor(ROT.RNG.getUniform() * r) + min

window.randChance = (chance) -> 
	return (ROT.RNG.getUniform() < chance)

window.randChoose = (choices) -> 
	choice = randInt(0, choices.length)
	return choices[choice]

window.assert = (condition, message = "Assertion failed") ->
    if not condition
        throw message

window.elemRemove = (array, elem) ->
	index = array.indexOf(elem)
	if index > -1
    	array.splice(index, 1)
