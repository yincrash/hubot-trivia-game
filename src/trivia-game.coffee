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
#   !hint - hints for trivia question
#
# Author:
#   yincrash

Fs = require 'fs'
Path = require 'path'
Cheerio = require 'cheerio'
Entities = require 'entities'

class ScoreKeeper
  constructor: (@robot) ->
    @cache =
      scores: {}

    @robot.brain.on "loaded", =>
      @robot.brain.data.scores ||= {}

      @cache.scores = @robot.brain.data.scores

  getUser: (user) ->
    @cache.scores[user] ||= 0
    user

  saveUser: (user) ->
    @robot.brain.data.scores[user] = @cache.scores[user]
    @robot.brain.emit("save", @robot.brain.data)

    @cache.scores[user]

  add: (user, value) ->
    user = @getUser(user)
    @cache.scores[user] += value
    @saveUser(user)

  scoreForUser: (user) -> 
    user = @getUser(user)
    @cache.scores[user]

  top: (amount) ->
    tops = []

    for name, score of @cache.scores
      tops.push(name: name, score: score)

    tops.sort((a,b) -> b.score - a.score).slice(0,amount)

  bottom: (amount) ->
    all = @top(@cache.scores.length)
    all.sort((a,b) -> b.score - a.score).reverse().slice(0,amount)

class Game
  @currentQ = null
  @hintLength = null

  constructor: (@robot, @scoreKeeper) ->
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
    link = $question("a").attr("href")
    text = Entities.decodeHTML($question("span").text())
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

      if checkGuess.indexOf(checkAnswer) >= 0
        resp.reply "YOU ARE CORRECT!!! The answer is #{@currentQ.answer}"
        name = resp.envelope.user.name.toLowerCase().trim()
        value = @currentQ.value.replace /[^0-9.-]+/g, ""
        @robot.logger.debug "#{name} answered correctly."

        value = parseInt value
        user = resp.envelope.user.mention_name.toLowerCase().trim()
        newScore = @scoreKeeper.add(user, value)
        if newScore? then resp.send "#{user} has #{newScore} points."

        @currentQ = null
        @hintLength = null
      else
        resp.send "#{guess} is incorrect."
    else
      resp.send "There is no active question!"

  hint: (resp) ->
    if @currentQ
      # Check if the hintLength is greater than answerLength/2
      if @hintLength > answer.length/2
        resp.send "You have run out of hints for the active question" 
        return

      answer = @currentQ.validAnswer
      hint = answer.substr(0,@hintLength) + answer.substr(@hintLength,(answer.length + @hintLength)).replace(/./g, ".")

      if @hintLength <= answer.length
        @hintLength += 1

      resp.send hint
    else
      resp.send "There is no active question!"    

  checkScore: (resp, name) ->
    name = name.toLowerCase().trim()
    score = @scoreKeeper.scoreForUser(name)
    resp.send "#{name} has #{score} points."

  leaderBoard: (resp, topOrBottom, amount) ->
    op = []
    tops = @scoreKeeper[topOrBottom](amount)

    for i in [0..tops.length-1]
      op.push("#{i+1}. #{tops[i].name} : #{tops[i].score}")

    resp.send op.join("\n")

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)
  game = new Game(robot, scoreKeeper)

  robot.hear /^!trivia/, (resp) ->
    game.askQuestion(resp)

  robot.hear /^!skip/, (resp) ->
    game.skipQuestion(resp)

  robot.hear /^!a(nswer)? (.*)/, (resp) ->
    game.answerQuestion(resp, resp.match[2])
  
  robot.hear /^!score (.*)/i, (resp) ->
    game.checkScore(resp, resp.match[1])

  robot.hear /!t (top|bottom)( \d+)?/i, (resp) ->
    amount = parseInt(resp.match[2])
    game.leaderBoard(resp, resp.match[1], amount)

  robot.hear /^!hint/i, (resp) ->
    game.hint(resp)
