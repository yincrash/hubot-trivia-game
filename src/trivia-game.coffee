# Description:
#   Play trivia! Doesn't include questions. Questions should be in the following JSON format:
#   {
#       "answer": "Pizza",
#       "category": "FOOD",
#       "question": "Crust, sauce, and toppings!",
#       "value": "$400"
#   },
#
# Dependencies:
#   cheerio - for questions with hyperlinks
#
# Configuration:
#   None
#
# Commands:
#   !trivia - ask a question
#   !skip - skip the current question
#   !answer <answer> or !a <answer> - provide an answer
#   !score <player> - check the score of the player
#
# Author:
#   yincrash

Fs = require 'fs'
Path = require 'path'
Cheerio = require 'cheerio'
FuzzySet = require 'fuzzyset.js'


class Game
  @currentQ = null

  constructor: (@robot) ->
    buffer = Fs.readFileSync(Path.resolve('./res', 'questions.json'))
    @questions = JSON.parse buffer
    @robot.logger.debug "Initiated trivia game script."
  
  askQuestion: (resp) ->
    unless @currentQ # set current question
      index = Math.floor(Math.random() * @questions.length)
      @currentQ = @questions[index]
      @robot.logger.debug "Answer is #{@currentQ.answer}"
      # remove optional portions of answer that are in parens
      @currentQ.validAnswer = @currentQ.answer.replace /\(.*\)/, ""

    $question = Cheerio.load ("<span>" + @currentQ.question + "</span>")
    link = $question('a').attr('href')
    text = $question('span').text()
    resp.send "Answer with !a or !answer\n" +
              "For #{@currentQ.value} in the category of #{@currentQ.category}:\n" +
              "#{text} " +
              if link then " #{link}" else ""

  skipQuestion: (resp) ->
    if @currentQ
      resp.send "The answer is #{@currentQ.answer}."
      @currentQ = null
      @askQuestion(resp)
    else
      resp.send "There is no active question!"
  
  answerQuestion: (resp, guess) ->
    if @currentQ
      checkGuess = guess.toLowerCase()
      # remove html entities (slack's adapter sends & as &amp; now)
      checkGuess = checkGuess.replace /&.{0,}?;/, ""
      # remove all punctuation and spaces, and see if the answer is in the guess.
      checkGuess = checkGuess.replace /[\\'"\.,-\/#!$%\^&\*;:{}=\-_`~()\s]/g, ""
      checkAnswer = @currentQ.validAnswer.toLowerCase().replace /[\\'"\.,-\/#!$%\^&\*;:{}=\-_`~()\s]/g, ""
      checkAnswer = checkAnswer.replace /^(a(n?)|the)/g, ""
      fuzzyAnswer = FuzzySet([checkAnswer])
      result = fuzzyAnswer.get(checkGuess)
      confidence = 0
      if result and result[0] and result[0][0]
        confidence = result[0][0]
      if confidence > 0.5
        resp.reply "YOU ARE CORRECT!!1!!!111!! The answer is #{@currentQ.answer}"
        name = resp.envelope.user.name.toLowerCase().trim()
        value = @currentQ.value.replace /[^0-9.-]+/g, ""
        @robot.logger.debug "#{name} answered correctly."
        user = resp.envelope.user
        user.triviaScore = user.triviaScore or 0
        user.triviaScore += parseInt value
        resp.reply "Score: #{user.triviaScore}"
        @robot.brain.save()
        @currentQ = null
      else
        resp.send "#{guess} is incorrect."
    else
      resp.send "There is no active question!"

  checkScore: (resp, name) ->
    user = @robot.brain.userForName name
    unless user
      resp.send "There is no score for #{name}"
    else
      user.triviaScore = user.triviaScore or 0
      resp.send "#{user.name} - $#{user.triviaScore}"


module.exports = (robot) ->
  game = new Game(robot)
  robot.hear /^!trivia/, (resp) ->
    game.askQuestion(resp)

  robot.hear /^!skip/, (resp) ->
    game.skipQuestion(resp)

  robot.hear /^!a(nswer)? (.*)/, (resp) ->
    game.answerQuestion(resp, resp.match[2])
  
  robot.hear /^!score (.*)/i, (resp) ->
    game.checkScore(resp, resp.match[1].toLowerCase().trim())
