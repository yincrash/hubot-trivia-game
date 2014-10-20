# Hubot Trivia Game Plugin

A trivia bot.

## Commands

*   **!trivia** - ask a question
*   **!skip** - skip the current question
*   **!answer <answer>** or **!a <answer>** - provide an answer
*   **!score <player>** - check the score of the player

## Installation

TBA

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
