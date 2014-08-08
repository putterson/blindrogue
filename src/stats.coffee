class global.Equipment
    constructor: () ->
        @items = []
    getEquipped: (type) ->
        for item in @items when item.isEquipped() and item.getType() == type
            return item
        return null
    getArmour: () -> @getEquipped "armour"
    getAmulet: () -> @getEquipped "amulet"
    getWeapon: () -> @getEquipped "weapon"
    onCalculate: (stats) ->
        @getWeapon()?.onCalculate(stats)
        @getArmour()?.onCalculate(stats)
        @getAmulet()?.onCalculate(stats)

class global.Item
    constructor: (@itemType) ->
        @equipped = false
        @identified = false
    equip: () -> @equipped = true
    unequip: () -> @equipped = false
    isEquipped: () -> @equipped
    getItemType: () -> @itemType
    getName: () -> @itemType.name
    getType: () -> @itemType.type
    getDescription: () -> @itemType.description
    getAppearsMsg: () -> @itemType.appearsMsg
    onCalculate: (stats) -> @itemType.onCalculate(stats, @)
    onUse: (stats) -> @itemType.onUse(stats, @)
    canUse: (stats) -> 
        if @itemType.onPrereq?
            [canUse, messageIfNot] = @itemType.onPrereq(stats, @)
            if not canUse 
                return [false, messageIfNot]
        return [true]

class global.Attack
    constructor: (@damage, @hitChance, @name, @traits, @attackHitDescription, @attackMissDescription) ->
        # Set above
    clone: () -> new Attack(@damage, @hitChance, @name, @traits, @attackHitDescription, @attackMissDescription)

class global.RawStats
    constructor: (@hp, @maxHp, @mp, @maxMp, @armourClass, @attack) ->
        # Stores passed attributes
    clone: () -> new RawStats(@hp, @maxHp, @mp, @maxMp, @armourClass, (if @attack then @attack.clone() else null))

global.makeAttack = (attack) -> new Attack(attack.damage, attack.hitChance, attack.name, attack.traits, attack.attackHitDescription, attack.attackMissDescription)
global.makeStats = (hp, mp, armourClass, attack) -> new RawStats(hp,hp, mp,mp, armourClass, makeAttack(attack))

class global.Stats
    constructor: (obj, stats) ->
        @obj = obj
        @base = stats
        @equipment = new Equipment()
        @copyBaseToDerived()
    getName: () -> @obj.getName()
    # Used at the start of a sentence
    wrapRegularVerb: (verb) -> @obj.wrapRegularVerb(verb)
    copyBaseToDerived: () ->
        @derived = @base.clone()
    recalculate: () ->
        @copyBaseToDerived()
        @equipment.onCalculate(@)
    getAttack: () -> @derived.attack
    # Attack an (E)nemy
    # Return resulting flavour text
    getEquipment: () -> @equipment
    getItems: () -> @equipment.items
    addItem: (item) ->
    	@equipment.items.push item
    useItem: (item) ->
        assert(item in @getItems())
        if item.onUse(@, item)
            elemRemove @getItems(), item

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
                text += "\n" + clc.greenBright randChoose(E.obj.monsterType.deathMsg).replace("$NAME", E.getName())
            else
                text += "Sad day... you died."
            E.obj.remove()
        return text.replace("$ENEMY", E.getName()).replace("$NAME", @getName())

# Create a initial stats from a stat data table (in data.coffee)
global.makeStatsFromData = (D) ->
    return makeStats(D.hp, D.mp, D.armourClass, makeAttack(D.attack))
