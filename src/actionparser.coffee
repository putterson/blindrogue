###############################################################################
# Actions are parsed by parsing a sequence of components.
# The shortest non-ambiguous string of characters for something
# can be used to signify it.
###############################################################################

defaultDescribe = (words, nWordsNeeded) -> words.join " "

filterPass = (str) ->
	str = str.replace(new RegExp(' ', 'g'),'').toLowerCase(); 
	return str.replace(new RegExp('ō', 'g'),'o').replace(new RegExp('\\?', 'g'),'')

findMatchingCharacters = (word, string, offset) ->
	matchedChars = 0
	len = Math.min(word.length, string.length - offset)
	for i in [0..len-1]
		if word[i] == string[i + offset]
			matchedChars = (i+1)
		else
			break
	return matchedChars

# ActionChoice: A possible choice of action. Many of these exist, for every combination of verb / target.
# Takes a description function which takes the amount of words needed and returns two lines, for short and long description. 
class global.ActionChoice
	# Principle: Do not need all words, only up to ambiguity
	# Number of words needed effects autocomplete suggestion.
	# Eg 'fight Keugeken north 1' if only 1 monster total can be 'fight Keugeken north'
	constructor: (@rawWords, @action, @describeFunc = defaultDescribe) ->
		@words = []
		for word in @rawWords
			# For purposes of matching:
			@words.push filterPass(word)
		@_resetMatchStats()
		@minimalWords = null # Set by setMinimalActionWords
		# Handle being passed a string:
		if typeof @describeFunc == "string"
			describeStr = @describeFunc
			@describeFunc = (words, nWordsNeeded) -> describeStr
	_resetMatchStats: () ->
		@matchedChars = 0
		@matchedWords = 0
		@firstWordMatched = false

	setMatchStats: (string) ->
		@_resetMatchStats()
		firstWord = true
		offset = 0
		for word in @words
			nMatched = findMatchingCharacters(word, string, offset)
			if nMatched > 0
				if firstWord
					@firstWordMatched = true
				@matchedWords++
			@matchedChars += nMatched
			offset += nMatched
			firstWord = false

	describe: () -> 
		return @describeFunc @rawWords, @minimalWords

tryMatch = (string, choice) ->

# Return string split with the component matched, and the rest
# If nothing matches, returns ["", string]
window.actionGreedyMatch = (string, wordNumber, choices) ->
	matchedChars = 0
	matchedWord = null
	# Loop over all possible choices
	for choice in choices
		if choice.words.length > wordNumber
			word = choice.words[wordNumber]
			len = Math.min(string.length, word.length)
			# Loop over the shorter of the two lengths
			for i in [0..len-1]
				if string[i] != word[i]
					break
				# Have we found a longer match?
				if i+1 > matchedChars
					matchedChars = i+1
					matchedWord = word

	return [string.substring(0, matchedChars), string.substring(matchedChars)]

# Filter choices that don't start with a prefix, in a given word position
filterChoices = (prefix, wordNumber, choices) ->
	newChoices = []
	for choice in choices
		if choice.words.length > wordNumber 
			# Test whether we start with the prefix matched by actionGreedyMatch?
			if choice.words[wordNumber].indexOf(prefix) == 0
				newChoices.push choice
	return newChoices

# Filter choices that have less characters matched than the max matched
filterShorterMatches = (choices) ->
	mostMatched = 0
	for {matchedChars} in choices
		mostMatched = Math.max matchedChars, mostMatched
	choices = (c for c in choices when c.matchedChars == mostMatched)
	return [choices, mostMatched]

class global.ActionChoiceSet
	constructor: (@choices) -> 
		@_setMinimalActionWords()

	# Set '@minimalWords' in all ActionChoice objects given.
	# O(N^2) algorithm.
	_setMinimalActionWords: () ->
		for choice in @choices
			minWords = 1
			cWords = choice.words
			# Loop through other choices to find longest streak of matching words
			for otherChoice in @choices
				if choice == otherChoice then continue
				oWords = otherChoice.words
				len = Math.min(oWords.length, cWords.length)
				for i in [0..len-1]
					if cWords[i] != oWords[i]
						break
					# Keep track of the longest matching-word streak
					# Set to one-past the ambiguous word matching
					minWords = Math.min Math.max(i+2, minWords), cWords.length
			choice.minimalWords = minWords

	# Return all the possible matches for a string.
	# Words are parsed greedily, consuming as many characters as possible.
	# Returns the possible choices, along with whether the parsing matched completely.
	possibleMatches: (string) ->
		# Remove withspace, and lower-case the string
		string = filterPass string
		choices = @choices

		# Set matching statistics for each string
		choice.setMatchStats(string) for choice in choices

		# Filter inferior matches
		[choices, mostMatched] = filterShorterMatches(choices)

		firstWordMatched = false
		allWordsMatched = false
		for choice in choices
			if choice.firstWordMatched
				firstWordMatched = true
			if choice.matchedWords >= choice.words.length
				allWordsMatched = true

		# If none matched the first word, fail but return choices now
		if not firstWordMatched
			return [choices, false]

		# Otherwise, filter choices without first word matched
		choices = (c for c in choices when c.firstWordMatched)

		# If a choice matched all words, filter all choices that don't match all words
		if allWordsMatched
			choices = (c for c in choices when c.matchedWords >= c.words.length)

		# Return current choices, and whether parsing of the string was completed fully
		parsingComplete = (mostMatched >= string.length)
		return [choices, parsingComplete]


		# Filter choices with less than maximum characters matched


		# # Remove withspace, and lower-case the string
		# string = filterPass string
		# wordNumber = 0
		# choices = @choices
		# invalidated = false
		# longestWordLen = () ->
		# 	longest = 0
		# 	for choice in choices 
		# 		longest = Math.max(longest, choice.words.length)
		# 	return longest

		# choice._resetMatchCounts() for choice in choices
		# while string != ""
		# 	[matchedComponent, newString] = actionGreedyMatch(string, wordNumber, choices)
		# 	string = newString # Update string
		# 	if matchedComponent == ""
		# 		# Don't allow skipping the first word:
		# 		if wordNumber == 0
		# 			invalidated = true

		# 		# Can we possibly parse further using the next word?
		# 		if longestWordLen() <= wordNumber + 1
		# 			# No further parsing possible!
		# 			# Parsing incomplete, but return what we have now (may still be useful suggestions).
		# 			return [choices, false]
		# 	else
		# 		choices = filterChoices(matchedComponent, wordNumber, choices)
		# 	choiceDescs = []
		# 	for choice in choices
		# 		choiceDescs.push choice.describe()
		# 	console.log "choices #{matchedComponent} #{newString} #{choiceDescs.join "\n"}"
		# 	wordNumber++
		# # Does anything take up all the words?
		# wordFullyParsed = false
		# for choice in @choices 
		# 	console.log "inprog #{wordNumber} vs #{choice.words.length} (#{choice.words})"
		# 	if wordNumber >= choice.words.length
		# 		wordFullyParsed = true
		# 		break
		# console.log "wordFullyParsed #{wordFullyParsed}"
		# # Filter anything not fully parsed:
		# if wordFullyParsed
		# 	choices = filterNonMinimalChoices(choices)

		# # Parsing-completed path. Returns multiple if string is so far ambiguous. 
		# # May have been invalidated (ie not matching first word)
		# # in which case we still show potential results of interest.
		# return [choices, (not invalidated)]
