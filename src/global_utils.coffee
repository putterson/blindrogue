# Global utilties for convenience

window.randInt = (min, max) -> 
	r = max - min
	return Math.floor(ROT.RNG.getUniform() * r) + min
