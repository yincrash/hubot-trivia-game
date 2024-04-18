/**
 * Answer Checker module
 * Checks answer using fuzzy matching of substrings of the guess.
 * @module answer-checker
 **/
import FuzzySet from "fuzzyset";

const goodConfidence = 0.65;

/**
 * check if the guess is valid for the given answer
 * this calls FuzzySet on every consecutive combination of words from the guess
 * by https://github.com/natgaertner
 **/
const AnswerChecker = (guess: string, answer: string) => {
    const result = keymax(pseudoPowerSet(guess.split(" ")), (element: string) => {
        const match = FuzzySet([answer]).get(element);
        if (match === null) {
            return 0;
        } else {
            return match[0][0];  // return the confidence level
        }
    });
    return result.maxScore >= goodConfidence;
};

/** return element and keyfunc result for the element for which keyfunc returns the highest value */
function keymax<Type>(set: Set<Type>, keyfunc: (element: Type) => number) {
    var maxElement = null, maxScore = 0, score;
    set.forEach((element) => {
        score = keyfunc(element);
        if (score > maxScore) {
            maxElement = element;
            return maxScore = score;
        }
    });
    return {
        maxElement: maxElement,
        maxScore: maxScore
    };
}

/** ['thin', 'crust', 'pizza'] => ['thin', 'crust', 'pizza', 'thin crust', 'crust pizza', 'thin crust pizza'] */
function pseudoPowerSet(words: Array<string>): Set<string> {
    var len = 1, set = new Set<string>(), start;
    while (len <= words.length) {
        start = 0;
        while (start <= words.length - len) {
            set.add(words.slice(start, start + len).join(" "));
            start++;
        }
        len++;
    }
    return set;
}

export default AnswerChecker;