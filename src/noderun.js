require('coffee-script/register')
//require('coffee-trace')

GLOBAL.window = GLOBAL
window.ROT = require('rot-js').ROT
window.readline = require('readline-sync')
window.readline = require('readline-sync')
window.clc = require('cli-color')

require('./global_utils.coffee')
require('./data.coffee')
require('./describe.coffee')
require('./mapqueries.coffee')
require('./stats.coffee')
require('./map.coffee')
require('./mapobjects.coffee')
require('./actionparse.coffee')
require('./view.coffee')
require('./main.coffee')
