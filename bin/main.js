// Generated by CoffeeScript 1.6.3
(function() {
  var action, answer, eX, eY, map, pX, pY, player, _ref, _ref1;

  map = new Map(40, 40);

  map.generate();

  _ref = map.randEmptySquare(), pX = _ref[0], pY = _ref[1];

  player = new PlayerObj(map, '@', pX, pY);

  map.addObject(player);

  _ref1 = map.randEmptySquare(), eX = _ref1[0], eY = _ref1[1];

  map.addObject(new MonsterObj(map, 'M', eX, eY));

  map.player = player;

  while (true) {
    answer = readline.question('What is your action? ');
    action = parseAction(answer);
    if (typeof action === 'string') {
      console.log(action);
      continue;
    }
    while (true) {
      if (!action.step(player)) {
        break;
      }
      player.computeFov();
      map.print();
    }
  }

}).call(this);
