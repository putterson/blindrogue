global.MONSTERS = {}
global.ITEMS = {}

# Helper for monster data
Monster = (data) ->
	data.appearsMsg = data.appearsMsg.replace("$NAME", data.name)
	MONSTERS[data.name] = data

Item = (data) ->
	data.appearsMsg = data.appearsMsg.replace("$NAME", data.name)
	ITEMS[data.name] = data

Consumable = (data) ->
	data.type = "consumable"
	Item(data)

Weapon = (data) ->
	data.type = "weapon"
	Item(data)

Amulet = (data) ->
	data.type = "amulet"
	Item(data)

###########################################
# Define player starting stats
###########################################

global.PLAYER_START_STATS = {
	hp: 15
	mp: 0
	# 'Base' armour class -- does not account for starting equipment
	armourClass: 0

	# 'Unarmed' attack information
	attack: {
		damage: 1
		hitChance: 5
		name: "fists"
		attackHitDescription: ["You kick the $ENEMY.", "You punch the $ENEMY."]
		attackMissDescription: ["You try to kick the $ENEMY, but are blocked!", "You try to punch the $ENEMY, but miss!"]
	}
}

###########################################
# Define monster data
###########################################

Monster {
	name: "Keukegen"
	char: "k"
	description: "It resembles a small dog covered entirely in long hair."
	appearsMsg: "You spot a fluffy, hostile $NAME!"
	deathMsg: [
		"The $NAME yelps as it bleeds out! It is dead."
		"The $NAME stops moving... it is dead."
	]

	hp: 3
	mp: 0
	armourClass: 0

	# 'Unarmed' attack information
	attack: {
		damage: 1
		hitChance: 5
		attackHitDescription: [
			"The $NAME bites your foot!"
			"The $NAME leaps and claws you!"
		]
		attackMissDescription: [
			"The $NAME tries to bite you, but you block it!"
			"The $NAME tries to leap, but you kick it away!"
		]
	}
}

###########################################
# Define item data
###########################################

UNKNOWN_POTION_DESCRIPTORS = [
	{name: "Shiny Potion", description: "The potion shines brilliantly.", appearsMsg: "You find a shining potion."}
]

Consumable {
	name: "Ale of Health"
	char: 'p'
	# TODO: RNG
	unidentifiedData: UNKNOWN_POTION_DESCRIPTORS[0]
	type: "consumable"
	# Only applies if identified:
	description: "A blessed brew that heals wounds when quaffed."
	appearsMsg: "You find a $NAME!"

	healAmount: 20

	onUse: (stats) ->
		stats.base.hp = Math.max(stats.derived.maxHp, stats.base.hp + @healAmount)
}

Weapon {
	name: "Bō"
	char: 'b'
	traits: ["staff"]
	description: "A very tall and long staff weapon."
	appearsMsg: "You spot a long wooden $NAME!"

	damage: 5
	accuracy: 5
	onCalculate: (stats) -> 
		stats.derived.attack = {
			damage: @attack
			traits: @traits
		}
}

UNKNOWN_AMULET_DESCRIPTORS = [
	{name: "Dull Amulet", description: "The amulet lacks luster.", appearsMsg: "You see a dull amulet."}
]

Amulet {
	name: "Amulet of Staffing"
	char: 'a'
	# TODO: RNG
	unidentifiedData: UNKNOWN_POTION_DESCRIPTORS[0]
	description: "Grants +2 attack with a staff."
	appearsMsg: "You spot a long wooden $NAME!"
	onCalculate: (stats) -> 
		attack = stats.derived.attack
		if attack and "staff" in attack.traits
			attack.damage += 2
}