class window.Equipment
	constructor: (weapon = null, amulet = null) ->
		@weapon = weapon
		@amulet = amulet
	onCalculate: (stats) ->
		@weapon.onCalculate(stats) unless @weapon == null
		@amulet.onCalculate(stats) unless @amulet == null

class window.RawStats
	constructor: (@hp, @maxHp, @mp, @maxMp, @attack) ->
		# Stores passed attributes
	clone: new RawStats(@hp, @maxHp, @mp, @maxMp, @attack)

class window.Stats
	constructor: (obj, hp, mp, attack) ->
		@obj = obj
		@base = new RawStats(hp,hp, mp,mp, attack)
		@copyBaseToDerived()
	copyBaseToDerived: () ->
		@derived = @base.clone()

