class window.ViewState
	constructor: () ->
		@items = []
		@mobs = []
		@room = null

		@squares = map.player.seenSquares
		@x = map.player.x
		@y = map.player.y

		for [x, y] in @squares
			obj = map.grid[x][y].object
			if obj != null
				if obj.type == 'monster'
					@mobs.push obj
				else if obj.type == 'item'
					@items.push obj

		for room in map.rooms
			if map.withinRoom @x @y
				@room = room
				break

class window.ViewDescriber
	constructor: () ->
		@curstate = new ViewState()
		@prestate = new ViewState()

	describe: () ->
		# @curstate = new ViewState()

		# Messages in description
		m = []

		if @curstate.room != null
			m.push 'You are in a room.'
		else
			m.push 'You are in a corridor.'

		for item in @curstate.items
			m.push 'You see an item.'

		for mob in @curstate.mobs
			m.push 'You see a monster.'

	step: () ->
		@prestate = curstate
		@curstate = new ViewState()

		# Messages generated by stepping
		m = []

		@compare(@curstate.mobs, @prestate.mobs, 'a monster.')
		@compare(@curstate.items, @prestate.items, 'an item.')

		for item in @curstate


		return m

	compare: (cur, prev, msg) ->
		m = []
		for t in cur
			if t not in prev
				m.push 'You spot ' + msg
		for t in prev
			if t not in cur
				m.push 'You lose sight of ' + msg
		return m