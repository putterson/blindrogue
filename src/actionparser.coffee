###############################################################################
# Actions are parsed by parsing a sequence of components.
# The shortest non-ambiguous string of characters for something
# can be used to signify it.
###############################################################################

defaultDescribe = (words, nWordsNeeded) -> words.join " "

filterPass = (str) ->
	str = str.replace(new RegExp(' ', 'g'),'').toLowerCase(); 
	return str.replace(new RegExp('ō', 'g'),'o').replace(new RegExp('\\?', 'g'),'')

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
		@minimalWords = null # Set by setMinimalActionWords
		# Handle being passed a string:
		if typeof @describeFunc == "string"
			describeStr = @describeFunc
			@describeFunc = (words, nWordsNeeded) -> describeStr
	describe: () -> 
		return @describeFunc @rawWords, @minimalWords


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

# Filter choices that have more words than the least amount of words.
filterNonMinimalChoices = (choices) ->
	leastN = 999 # Arbitrarily large 
	for {words} in choices
		leastN = Math.min words.length, leastN
	newChoices = []
	for choice in choices
		if choice.words.length <= leastN
			newChoices.push choice
	return newChoices

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
		wordNumber = 0
		choices = @choices
		longestWordLen = () ->
			longest = 0
			for choice in choices 
				longest = Math.max(longest, choice.words.length)
			return longest

		while string != ""
			[matchedComponent, newString] = actionGreedyMatch(string, wordNumber, choices)
			string = newString # Update string
			if matchedComponent == ""
				# Can we possibly parse further using the next word?
				if longestWordLen() <= wordNumber + 1
					# No further parsing possible!
					# Parsing incomplete, but return what we have now (may still be useful suggestions).
					return [choices, false]
			else
				choices = filterChoices(matchedComponent, wordNumber, choices)
			wordNumber++
		choices = filterNonMinimalChoices(choices)
		# Parsing-completed path. Returns multiple if string is so far ambiguous. 
		return [choices, true]
