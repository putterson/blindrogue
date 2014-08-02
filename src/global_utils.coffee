# Global utilties for convenience

window.randInt = (min, max) -> 
	r = max - min
	return Math.floor(ROT.RNG.getUniform() * r) + min

window.randChance = (chance) -> 
	return (ROT.RNG.getUniform() < chance)

window.assert = (condition, message = "Assertion failed") ->
    if not condition
        throw message
