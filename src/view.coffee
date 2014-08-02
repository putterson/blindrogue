class window.ViewState
	constructor:
		@items = []
		@mobs = []
		@room = null

		@squares = map.player.seenSquares
		@x = map.player.x
		@y = map.player.y



		for square in @squares
			if obj.type == 'monster'
				@mobs.push obj
			else if obj.type == 'item'
				@items.push obj
