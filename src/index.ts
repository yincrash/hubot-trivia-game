import fs from "fs";
import { Robot } from "hubot";
import path from "path";
import GameSetup from "./trivia-game.js";

const HubotTriviaGame = (robot: Robot & { commands: Array<string>}) => {
    const commands = robot.commands;
    commands.push("!trivia - ask a question");
    commands.push("!skip - skip the current question");
    commands.push("!answer <answer> or !a <answer> - provide an answer");
    commands.push("!hint or !h - take a hint");
    commands.push("!score <player> - check the score of the player");
    commands.push("!scores or !score all - check the score of all players");

    return GameSetup(robot as Robot);
};

export default HubotTriviaGame;