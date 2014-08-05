console.log "test_actionverbs.coffee: Running tests for actionverbs.coffee"

tests = []

describeMinimal = (words, nNeeded) ->
	console.log words, nNeeded
	str = ''
	for i in [0..nNeeded-1]
		str += words[i] + " "
	return str.trim()

AC = (str) -> new ActionChoice str.split(" "), describeMinimal

tests.push () ->
	console.log "Test action description"

	ACS = new ActionChoiceSet [
		AC "fight Keugeken north 1"
		AC "fight Keugeken south 2"
	]

	assert ACS.choices[0].describe() == "fight Keugeken north"
	assert ACS.choices[1].describe() == "fight Keugeken south"

	ACS = new ActionChoiceSet [
		AC "fight Keugeken north 1"
		AC "fight Keugeken north 2"
	]

	assert ACS.choices[0].describe() == "fight Keugeken north 1"
	assert ACS.choices[1].describe() == "fight Keugeken north 2"


for test in tests
	test()