###############################################################################
# Actions are parsed by parsing a sequence of components.
# The shortest non-ambiguous string of characters for something
# can be used to signify it.
###############################################################################

defaultDescribe = (words, nWordsNeeded) -> words.join " "

# ActionChoice: A possible choice of action. Many of these exist, for every combination of verb / target.
# Takes a description function which takes the amount of words needed and returns two lines, for short and long description. 
class global.ActionChoice
	# Principle: Do not need all words, only up to ambiguity
	# Number of words needed effects autocomplete suggestion.
	# Eg 'fight Keugeken north 1' if only 1 monster total can be 'fight Keugeken north'
	constructor: (words, @describeFunc = defaultDescribe) ->
		@rawWords = words
		@words = []
		for word in words
			# For purposes of matching:
			@words.push word.toLowerCase()
		@minimalWords = null # Set by setMinimalActionWords
	describe: () -> 
		return @describeFunc @rawWords, @minimalWords


# Return matched word, and rest of string.
# 'null' is returned if nothing matches
greedyMatch = (string, wordNumber, choices) ->
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

	return [matchedWord, string.substring(matchedChars)]

# Filter choices that don't contain a word in a given position
filterChoices = (word, wordNumber, choices) ->
	newChoices = []
	for choice in choices
		if choice.words.length > wordNumber and choice.words[wordNumber] == word
			newChoices.push choice
	return newChoices

class global.ActionChoiceSet
	constructor: (@choices) -> @_setMinimalActionWords()

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
					minWords = Math.max(i+2, minWords)
					console.log(choice.words, otherChoice.words, minWords)
					assert cWords.length >= minWords
			choice.minimalWords = minWords

	# Return all the possible matches for a string.
	# Words are parsed greedily, consuming as many characters as possible.
	possibleMatches: (string) ->
		wordNumber = 0
		choices = @choices
		while string != ""
			[matchedWord, matchedChars] = greedyMatch(string, wordNumber, choices)
			if matchedWord == null
				# No possibilities!
				return []
			choices = filterChoices(matchedWord, wordNumber, choices)
			wordNumber++
		return choices
