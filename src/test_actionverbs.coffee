console.log "test_actionverbs.coffee: Running tests for actionverbs.coffee"

tests = []

describeMinimal = (words, nNeeded) ->
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

tests.push () ->
	console.log "Test action resolution"

	choice1 = AC "fight Keugeken north 1"
	choice2 = AC "fight Keugeken north 2"
	choice3 = AC "fight Puttersan north 2"

	ACS = new ActionChoiceSet [choice1, choice2, choice3]

	# Test parsing with just 'f'
	[resolved, rest] = ACS.possibleMatches "f"
	assert(rest == '')
	assert(choice1 in resolved)
	assert(choice2 in resolved)
	assert(choice3 in resolved)

	# Test parsing with 'fk'
	[resolved, rest] = ACS.possibleMatches "fk"
	assert(rest == '')
	assert(choice1 in resolved)
	assert(choice2 in resolved)
	assert(not (choice3 in resolved))

for test in tests
	test()