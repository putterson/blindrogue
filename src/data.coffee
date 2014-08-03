window.MONSTERS = {}
window.ITEMS = {}

# Helper for monster data
Monster = (data) ->
	data.appears = data.appears.replace("$NAME", data.name)
	MONSTERS[data.name] = data

Item = (data) ->
	data.appears = data.appears.replace("$NAME", data.name)
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
# Define monster data
###########################################

Monster {
	name: "Keukegen"
	char: "k"
	description: "It resembles a small dog covered entirely in long hair."
	appears: "You spot a fluffy, hostile $NAME!"

	hp: 10
	speed: 0.75
}

###########################################
# Define item data
###########################################

UNKNOWN_POTION_DESCRIPTORS = [
	{name: "Shiny Potion", description: "The potion shines brilliantly.", appears: "You find a shining potion."}
]

Consumable {
	name: "Potion of Health"
	char: 'p'
	# TODO: RNG
	unidentifiedData: UNKNOWN_POTION_DESCRIPTORS[0]
	type: "consumable"
	# Only applies if identified:
	description: "A blessed brew that heals wounds when quaffed."
	appears: "You find a $NAME!"

	healAmount: 20

	onUse: (stats) ->
		stats.base.hp = Math.max(stats.derived.maxHp, stats.base.hp + @healAmount)
}

Weapon {
	name: "Bō"
	char: 'b'
	traits: ["staff"]
	description: "A very tall and long staff weapon."
	appears: "You spot a long wooden $NAME!"

	damage: 5
	onCalculate: (stats) -> 
		stats.derived.attack = {
			damage: @attack
			traits: @traits
		}
}

UNKNOWN_AMULET_DESCRIPTORS = [
	{name: "Dull Amulet", description: "The amulet lacks luster.", appears: "You see a dull amulet."}
]

Amulet {
	name: "Amulet of Staffing"
	char: 'a'
	# TODO: RNG
	unidentifiedData: UNKNOWN_POTION_DESCRIPTORS[0]
	description: "Grants +2 attack with a staff."
	appears: "You spot a long wooden $NAME!"
	onCalculate: (stats) -> 
		attack = stats.derived.attack
		if attack and "staff" in attack.traits
			attack.damage += 2
}