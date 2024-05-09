# Hubot Trivia Game Plugin

A trivia bot.

## Commands

*   **!trivia** - ask a question
*   **!skip** - skip the current question
*   **!answer <answer>** or **!a <answer>** - provide an answer
*   **!score <player>** - check the score of the player
*   **!scores** or **!score all** - check the score of all players
*   **!h** or **!hint** - take a hint

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
One example of such a question set can be found [here](http://www.reddit.com/r/datasets/comments/1uyd0t/200000_jeopardy_questions_in_a_json_file).

The file needs to be stored in `<hubot_root>/res/questions.json`

## Settings

Some settings can be set via `.env` config for your Hubot instance.

```
# The minimum unique skip requests required before the question is actually skipped.
# This prevents any single person from continually skipping questions alone.
# By default, no minimum.
MIN_SKIP_REQUESTS=0
```
