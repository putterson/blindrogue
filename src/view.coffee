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
		@describe


	describe: () ->
		# @curstate = new ViewState()

		if @curstate.room != null
			console.log 'You are in a room.'
		else
			console.log 'You are in a corridor.'

		for item in @curstate.items
			console.log 'You see an item.'

		for mob in @curstate.mobs
			console.log 'You see a monster.'

	step: () ->
		@prestate = curstate
		@curstate = new ViewState()

		for mob in @curstate
			if mob not in @prestate
				console.log 'You spot a monster!'


		for mob in @prestate
			if mob not in @curstate
				console.log 'You lose sight of a monster.'
