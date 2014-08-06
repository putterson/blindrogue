console.report "test_actionparser.coffee: Running tests for actionparser.coffee"

tests = []

describeMinimal = (words, nNeeded) ->
	str = ''
	for i in [0..nNeeded-1]
		str += words[i] + " "
	return str.trim()

AC = (str) -> new ActionChoice str.split(" "), null, describeMinimal

tests.push () ->
	console.report "Test action description"

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
	console.report "Test action resolution"

	choice1 = AC "fight Keugeken north 1"
	choice2 = AC "fight Keugeken north 2"
	choice3 = AC "fight Puttersan north 2"

	ACS = new ActionChoiceSet [choice1, choice2, choice3]

	# Test parsing with just 'f'
	[resolved, fullyMatched] = ACS.possibleMatches "f"
	assert(fullyMatched)
	assert(choice1 in resolved)
	assert(choice2 in resolved)
	assert(choice3 in resolved)

	# Test parsing with 'fk'
	[resolved, fullyMatched] = ACS.possibleMatches "fk"
	assert(fullyMatched)
	assert(choice1 in resolved)
	assert(choice2 in resolved)
	assert(not (choice3 in resolved))

	# Test parsing with 'fight keug@@@'
	[resolved, fullyMatched] = ACS.possibleMatches "fight keug@@@"
	assert(not fullyMatched)
	assert(choice1 in resolved)
	assert(choice2 in resolved)
	assert(not (choice3 in resolved))

	# Test parsing with 'fkn2'
	[resolved, fullyMatched] = ACS.possibleMatches "fkn2"
	assert(fullyMatched)
	assert(resolved.length == 1)
	assert(resolved[0] == choice2)

for test in tests
	test()