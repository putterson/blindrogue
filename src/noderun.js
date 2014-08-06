require('coffee-script/register')
//require('coffee-trace')

GLOBAL.global = GLOBAL
global.ROT = require('rot-js').ROT
global.readline = require('readline-sync')
global.readline = require('readline-sync')
global.clc = require('cli-color')

require('./global_utils.coffee')
require('./data.coffee')
require('./describe.coffee')
require('./mapqueries.coffee')
require('./stats.coffee')
require('./map.coffee')
require('./mapobjects.coffee')
require('./actionparse.coffee')
require('./view.coffee')
require('./actionverbs.coffee')
if (process.env.TEST) {
	require('./test_actionverbs.coffee')
} else {
	require('./main.coffee')
}
