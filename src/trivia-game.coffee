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
#   !hint or !h - take a hint
#   !score <player> - check the score of the player
#   !scores or !score all - check the score of all players
#
# Author:
#   yincrash

Fs = require 'fs'
Path = require 'path'
Cheerio = require 'cheerio'
AnswerChecker = require './answer-checker'

class Game
  @currentQ = null
  @hintLength = null

  constructor: (@robot) ->
    buffer = Fs.readFileSync(Path.resolve('./res', 'questions.json'))
    @questions = JSON.parse buffer
    @robot.logger.debug "Initiated trivia game script."

  askQuestion: (resp) ->
    unless @currentQ # set current question
      index = Math.floor(Math.random() * @questions.length)
      @currentQ = @questions[index]
      @hintLength = 1
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
      @hintLength = null
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
      if AnswerChecker(checkGuess, checkAnswer)
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
        @hintLength = null
      else
        resp.send "#{guess} is incorrect."
    else
      resp.send "There is no active question!"

  hint: (resp) ->
    if @currentQ
      answer = @currentQ.validAnswer
      hint = answer.substr(0,@hintLength) + answer.substr(@hintLength,(answer.length + @hintLength)).replace(/./g, ".")
      if @hintLength <= answer.length
        @hintLength += 1
      resp.send hint
    else
      resp.send "There is no active question!"

  checkScore: (resp, name) ->
    if name == "all"
      scores = ""
      for user in @robot.brain.usersForFuzzyName ""
        user.triviaScore = user.triviaScore or 0
        scores += "#{user.name} - $#{user.triviaScore}\n"
      resp.send scores
    else
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

  robot.hear /^!scores/i, (resp) ->
    game.checkScore(resp, "all")

  robot.hear /^!h(int)?/, (resp) ->
    game.hint(resp)
