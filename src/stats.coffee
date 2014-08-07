class global.Equipment
	constructor: () ->
		@weapon = null
		@amulet = null
		@items = []
	onCalculate: (stats) ->
		@weapon.onCalculate(stats) unless @weapon == null
		@amulet.onCalculate(stats) unless @amulet == null

class global.Attack
	constructor: (@damage, @hitChance, @name, @attackHitDescription, @attackMissDescription) ->
		# Set above
	clone: () -> new Attack(@damage, @hitChance, @name, @attackHitDescription, @attackMissDescription)

class global.RawStats
	constructor: (@hp, @maxHp, @mp, @maxMp, @armourClass, @attack) ->
		# Stores passed attributes
	clone: () -> new RawStats(@hp, @maxHp, @mp, @maxMp, @armourClass, (if @attack then @attack.clone() else null))

global.makeAttack = (attack) -> new Attack(attack.damage, attack.hitChance, attack.name, attack.attackHitDescription, attack.attackMissDescription)
global.makeStats = (hp, mp, armourClass, attack) -> new RawStats(hp,hp, mp,mp, armourClass, makeAttack(attack))

class global.Stats
	constructor: (obj, stats) ->
		@obj = obj
		@base = stats 
		@copyBaseToDerived()
	getName: () -> @obj.getName()
	# Used at the start of a sentence
	wrapRegularVerb: (verb) -> @obj.wrapRegularVerb(verb)
	copyBaseToDerived: () ->
		@derived = @base.clone()
	getAttack: () -> @derived.attack
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
		E.base.hp = Math.max(0, E.base.hp - A.damage)
		if E.base.hp <= 0
			if E.obj instanceof MonsterObj
				text += "\n" + clc.magenta randChoose(E.obj.monsterType.deathMsg).replace("$NAME", E.getName())
			else
				text += "Sad day... you died."
			E.obj.remove()
		return text.replace("$ENEMY", E.getName()).replace("$NAME", @getName())

# Create a initial stats from a stat data table (in data.coffee)
global.makeStatsFromData = (D) ->
    return makeStats(D.hp, D.mp, D.armourClass, makeAttack(D.attack))

