# Hubot Trivia Game Plugin

A trivia bot.

## Commands

*   **!trivia** - ask a question
*   **!skip** - skip the current question
*   **!answer <answer>** or **!a <answer>** - provide an answer
*   **!score <player>** - check the score of the player

## Installation

* In your hubot installation's path:
* `npm install hubot-trivia-game --save`
* edit `external-scripts.json` and add `hubot-trivia-game` to the JSON array.
* if the file doesn't exist, create it with `["hubot-trivia-game"]`
* add a `questions.json` file to `res/` folder which you may also need to create

### Question DB

The question database is a file containing a JSON array of questions with the following properties:
```
{
  "answer": "Pizza",
  "category": "FOOD",
  "question": "Crust, sauce, and toppings!",
  "value": "$400"
},
```
Extract the `data/jeopardy_questions.json.gz` and store it in `<hubot_root>/res/questions.json`
