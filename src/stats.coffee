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
	clone: () -> new RawStats(@hp, @maxHp, @mp, @maxMp, (if @attack then @attack.clone() else null))

window.makeStats = () -> (hp, mp, armourClass, attack) -> new RawStats(hp,hp, mp,mp, armourClass, attack)

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
	resolveText: (text) -> text.replace("$ENEMY", E.getName())
	useAttack: (E) ->
		Ed = E.derived
		A = @derived.attack
		# Like a 20-sided die
		rollNeeded = (Ed.armourClass - A.hitChance) + 10
		if randInt(1,21) >= rollNeeded
			# Success
			text = A.attackHitDescription + " " + @wrapRegularVerb("deal") + " #{A.damage} damage!"
		else
			text = A.attackMissDescription
		return @resolveText text

# Create a initial stats from a stat data table (in data.coffee)
window.makeStatsFromData = (D) ->
    A = D.attack
    attack = new Attack(A.damage, A.hitChance, A.attackHitDescription, A.attackMissDescription)
    return makeStats(D.hp, D.mp, D.armourClass, attack)

