class window.Equipment
	constructor: () ->
		@weapon = null
		@amulet = null
		@items = []
	onCalculate: (stats) ->
		@weapon.onCalculate(stats) unless @weapon == null
		@amulet.onCalculate(stats) unless @amulet == null

class window.Attack
	constructor: (@damage, @hitChance, @attackHitDescription, @attackMissDescription) ->
		# Set above
	clone: () -> new Attack(@damage, @hitChance, @attackHitDescription, @attackMissDescription)

class window.RawStats
	constructor: (@hp, @maxHp, @mp, @maxMp, @armourClass, @attack) ->
		# Stores passed attributes
	clone: () -> new RawStats(@hp, @maxHp, @mp, @maxMp, @armourClass, (if @attack then @attack.clone() else null))

window.makeAttack = (attack) -> new Attack(attack.damage, attack.hitChance, attack.attackHitDescription, attack.attackMissDescription)
window.makeStats = (hp, mp, armourClass, attack) -> new RawStats(hp,hp, mp,mp, armourClass, makeAttack(attack))

class window.Stats
	constructor: (obj, stats) ->
		@obj = obj
		@base = stats 
		@copyBaseToDerived()
	getName: () -> @obj.getName()
	# Used at the start of a sentence
	wrapRegularVerb: (verb) -> @obj.wrapRegularVerb(verb)
	copyBaseToDerived: () ->
		@derived = @base.clone()
	# Attack an (E)nemy
	# Return resulting flavour text
	useAttack: (E) ->
		Ed = E.derived
		A = @derived.attack
		# Like a 20-sided die
		rollNeeded = (Ed.armourClass - A.hitChance) + 10
		if randInt(1,21) >= rollNeeded
			# Success
			text = randChoose(A.attackHitDescription) + " " + @wrapRegularVerb("deal") + " #{A.damage} damage!"
			text = clc.red(text)
		else
			text = clc.blackBright(randChoose(A.attackMissDescription))
		return text.replace("$ENEMY", E.getName()).replace("$NAME", @getName())

# Create a initial stats from a stat data table (in data.coffee)
window.makeStatsFromData = (D) ->
    A = D.attack
    attack = new Attack(A.damage, A.hitChance, A.attackHitDescription, A.attackMissDescription)
    return makeStats(D.hp, D.mp, D.armourClass, attack)

