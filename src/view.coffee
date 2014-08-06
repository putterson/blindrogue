class global.ViewState
	constructor: (map) ->
		@items = []
		@mobs = []
		@room = null

		@squares = map.player.seenSqrs
		@x = map.player.x
		@y = map.player.y

		for [x, y] in @squares
			objs = map.getObjects(x,y)
			for obj in objs
				if obj != null
					if obj instanceof MonsterObj
						@mobs.push obj
					else if obj instanceof ItemObj
						@items.push obj

		for room in map.rooms
			if room.within(@x, @y)
				@room = room
				break

class global.ViewDescriber
	constructor: (map) ->
		@map = map
		@curstate = new ViewState(@map)
		@prestate = new ViewState(@map)
		@events = []

	describe: () ->
		# @curstate = new ViewState()

		# Messages in description
		m = []

		m = m.concat @describeroom(@curstate.room)

		for item in @curstate.items
			m.push 'You see an item.'

		for mob in @curstate.mobs
			m.push 'You see a monster.'

		return m

	# Describe the room/corridor you are in
	# room: MapRoom or null for corridor
	# step: false for normal describe, true if stepping
	describeroom: (room, step) ->
		m = []
		verb = ""
		size = ""
		shape = ""
		plural = ""
		seendoors = ""
		doors = []
		

		if step
			verb = 'enter'
		else
			verb = 'are in'


		if @curstate.room instanceof MapRoom
			for d in room.doors
				if @map.player.seen(d.x, d.y)
					doors.push d

			if doors.length == 0
				seendoors = "no"
			else
				seendoors = doors.length

			[w, h] = @curstate.room.size()
			s = w * h

			if s <= 3 * 3
				size = "cramped"
			else if s <= 4 * 4
				size = "small"
			else if s <= 5 * 5
				size = "spacious"
			else if s > 5 * 5
				size = "cavernous"


			if w >= 2 * h
				shape = " flanking"
			else if w >= 1.5 * h
				shape = " broad"

			if h >= 2 * w
				shape = " pinched"
			else if h >= 1.5 * w
				shape = " narrow"

			if seendoors > 1 or seendoors == "no"
				plural = "s"

			m.push "You #{verb} a #{size}#{shape} room with #{seendoors} door#{plural} in view."

			walldoorstring = ""
			if seendoors != "no"
				for k, v of @walldoors(room)
					walldoorstring += ""
				
		else
			m.push "You #{verb} a corridor"

		return m

	walldoors: (room, dir) ->
		walls = {"N" : 0, "E" : 0, "S" : 0, "W" : 0}

		#North wall
		for d in room.doors
			if d.x == room.x1
				walls["N"]++
			else if d.x == room.x2
				walls["S"]++
			else if d.y == room.y1
				walls["W"]++
			else if d.y == room.y2
				walls["E"]++

		return walls


	step: () ->
		@prestate = @curstate
		@curstate = new ViewState(@map)

		# Messages generated by stepping
		m = []

		m = m.concat @compare(@curstate.mobs, @prestate.mobs, (m) -> return m.monsterType.appears)
		m = m.concat @compare(@curstate.items, @prestate.items, (m) -> return m.itemType.appears)

		if @prestate.room != @curstate.room
			m = m.concat @describeroom(@curstate.room, true)

		return m

	compare: (cur, prev, msg) ->
		m = []
		for t in cur
			if t not in prev
				m.push msg(t)
		for t in prev
			if t not in cur and t instanceof MonsterObj
				m.push 'You lose sight of ' + t.monsterType.name
		return m

	pushevent: (event) ->
		@events.push event