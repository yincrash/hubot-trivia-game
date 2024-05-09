/**
 * Description:
 *   Play trivia! Doesn't include questions. Questions should be in the following JSON format:
 *   {
 *       "answer": "Pizza",
 *       "category": "FOOD",
 *       "question": "Crust, sauce, and toppings!",
 *       "value": "$400"
 *   },
 * 
 * Dependencies:
 *   cheerio - for questions with hyperlinks
 * 
 * Configuration:
 *   None
 * 
 * Commands:
 *   !trivia - ask a question
 *   !skip - skip the current question
 *   !answer <answer> or !a <answer> - provide an answer
 *   !hint or !h - take a hint
 *   !score <player> - check the score of the player
 *   !scores or !score all - check the score of all players
 * 
 * Author:
 *   yincrash
 * 
 * @module hubot-trivia-game
 **/

import fs from "fs";
import Path from "path";
import Cheerio from "cheerio";
import AnswerChecker from "./answer-checker.js";
import { Response, Robot, User } from "hubot";
import "dotenv/config";

const triviaScoreKey = "triviaScore";
const minSkipRequests = process.env.MIN_SKIP_REQUESTS ? +process.env.MIN_SKIP_REQUESTS : null;

class Game {
    currentQ?: Question;
    skipRequests: Array<string> = [];
    validAnswer?: string;
    hintLength = 0;
    questions: Array<Question> = [];

    constructor(public robot: Robot) {
        const buffer = fs.readFileSync(Path.resolve("./res", "questions.json"), "utf8");
        this.questions = JSON.parse(buffer);
        this.robot.logger.debug("Initiated trivia game script.");
    }

    public askQuestion(resp: Response) {
        var $question, index, link, text;
        if (!this.currentQ) {  // set current question
            index = Math.floor(Math.random() * this.questions.length);
            this.currentQ = this.questions[index];
            this.hintLength = 1;
            this.skipRequests = [];
            this.robot.logger.debug("Answer is " + this.currentQ.answer);
            // remove optional portions of answer that are in parens
            this.validAnswer = this.currentQ.answer.replace(/\(.*\)/, "");
        }

        $question = Cheerio.load("<span>" + this.currentQ.question + "</span>");
        link = $question("a").attr("href");
        text = $question("span").text();
        return resp.send("Answer with !a or !answer\n" + ("For " + this.currentQ.value + " in the category of " + this.currentQ.category + ":\n") + (text + " ") + (link ? " " + link : ""));
    }

    public skipQuestion(resp: Response) {
        if (this.currentQ) {
            let requestor = resp.envelope.user.id;
            if (this.skipRequests.indexOf(requestor) === -1) this.skipRequests.push(requestor)
            if (minSkipRequests && this.skipRequests.length < minSkipRequests) {
                return resp.send(`${this.skipRequests.length} of ${minSkipRequests} required unique skip requests received.` )
            } else {
                resp.send("The answer is " + this.currentQ.answer + ".");
                this.currentQ = undefined;
                this.skipRequests = [];
                this.hintLength = 0;
                return this.askQuestion(resp);
            }
        } else {
            return resp.send("There is no active question!");
        }
    }

    public answerQuestion(resp: Response, guess: string) {
        var checkAnswer, checkGuess, name, user, value;
        if (this.currentQ) {
            checkGuess = guess.toLowerCase();
            // remove html entities (slack's adapter sends & as &amp; now)
            checkGuess = checkGuess.replace(/&.{0,}?;/, "");
            // remove all punctuation and see if the answer is in the guess.
            checkGuess = checkGuess.replace(/[\\'"\.,-\/#!$%\^&\*;:{}=\-_`~()]/g, "");
            checkAnswer = this.validAnswer?.toLowerCase().replace(/[\\'"\.,-\/#!$%\^&\*;:{}=\-_`~()]/g, "") ?? "Error: No valid answer set!";
            checkAnswer = checkAnswer.replace(/^(a(n?)|the)/g, "");
            if (AnswerChecker(checkGuess, checkAnswer)) {
                resp.reply("YOU ARE CORRECT!!1!!!111!! The answer is " + this.currentQ.answer);
                name = resp.envelope.user.name.trim();
                value = this.currentQ.value.replace(/[^0-9.-]+/g, "");
                this.robot.logger.debug(name + " answered correctly.");
                user = this.robot.brain.userForId(resp.envelope.user.id, resp.envelope.user);
                user[triviaScoreKey] = (user[triviaScoreKey] as number ?? 0) + parseInt(value);
                resp.reply("Score: " + user[triviaScoreKey]);
                this.robot.brain.save();
                this.currentQ = undefined;
                this.hintLength = 0;
            } else {
                resp.send(guess + " is incorrect.");
            }
        } else {
            resp.send("There is no active question!");
        }
    }

    public hint(resp: Response) {
        if (this.currentQ) {
            var answer = this.validAnswer ?? "Error: No valid answer set!";
            var hint = answer.substr(0, this.hintLength) + answer.substr(this.hintLength, answer.length + this.hintLength).replace(/./g, ".");
            if (this.hintLength <= answer.length) {
                this.hintLength += 1;
            }
            resp.send(hint);
        } else {
            resp.send("There is no active question!");
        }
    }

    public checkScore(resp: Response, name: string) {
        if (name === "all") {
            this.robot.logger.debug("Requested all scores.");
            var scores = "";
            const users =  this.robot.brain.users();
            // type declaration is wrong - users() returns an object
            for(const key in users) {
                const user: User = users[key];
                if (user[triviaScoreKey]) {
                    scores += user.name + " - $" + user[triviaScoreKey] + "\n";
                }
            }
            resp.send(scores);
        } else {
            var user = this.robot.brain.userForName(name);
            if (!user || !user[triviaScoreKey]) {
                resp.send("There is no score for " + name);
            } else {
                user[triviaScoreKey] = user[triviaScoreKey] || 0;
                resp.send(user.name + " - $" + user[triviaScoreKey]);
            }
        }
    }
}

interface Question {
    answer: string,
    category: string,
    question: string,
    value: string,
};

export default function GameSetup(robot: Robot) {
    const game = new Game(robot);
    robot.hear(/^!trivia/, (resp: Response) => game.askQuestion(resp));

    robot.hear(/^!skip/, (resp: Response) => game.skipQuestion(resp));

    robot.hear(/^!a(nswer)? (.*)/, (resp: Response) => game.answerQuestion(resp, resp.match[2]));

    robot.hear(/^!score (.*)/i, (resp: Response) => game.checkScore(resp, resp.match[1].toLowerCase().trim()));

    robot.hear(/^!scores/i, (resp: Response) => game.checkScore(resp, "all"));

    robot.hear(/^!h(int)?/, (resp: Response) => game.hint(resp));
};
