// Generated by CoffeeScript 1.6.3
(function() {
  var eX, eY, map, pX, pY, _ref, _ref1;

  map = new Map(40, 40);

  map.generate();

  _ref = map.randEmptySquare(), pX = _ref[0], pY = _ref[1];

  map.addObject(new PlayerObj(map, '@', pX, pY));

  _ref1 = map.randEmptySquare(), eX = _ref1[0], eY = _ref1[1];

  map.addObject(new MonsterObj(map, 'M', eX, eY));

  map.print();

}).call(this);
