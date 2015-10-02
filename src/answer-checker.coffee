#
# Answer Checker module
# Checks answer using fuzzy matching of substrings of the guess.
# @module answer-checker

FuzzySet = require 'fuzzyset.js'
  
goodConfidence = 0.65
  
# check if the guess is valid for the given answer
# this calls FuzzySet on every consecutive combination of words from the guess
# by https://github.com/natgaertner
module.exports = (guess, answer) ->
  result = keymax(pseudoPowerSet(guess.split(' ')), (element) ->
    match = FuzzySet([answer]).get(element)
    if match == null
      0
    else
      match[0][0] # return the confidence level
  )
  return result.maxScore >= goodConfidence
  
# return element and keyfunc result for the element for which keyfunc returns the highest value
keymax = (set, keyfunc) ->
  maxElement = null
  maxScore = 0
  for idx of set
    element = set[idx]
    score = keyfunc(element)
    if score > maxScore
      maxElement = element
      maxScore = score
  {
    maxElement: maxElement
    maxScore: maxScore
  }
  
# ['thin', 'crust', 'pizza'] => ['thin', 'crust', 'pizza', 'thin crust', 'crust pizza', 'thin crust pizza']
pseudoPowerSet = (words) ->
  set = []
  len = 1
  while len <= words.length
    start = 0
    while start <= words.length - len
      set.push words.slice(start, start + len).join(' ')
      start++
    len++
  set
