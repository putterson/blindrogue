class window.ViewState
	constructor:
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
