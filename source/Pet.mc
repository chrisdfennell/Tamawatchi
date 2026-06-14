import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Time;

const PET_DOG = 0;
const PET_CAT = 1;
const PET_DRAGON = 2;
const PET_PENGUIN = 3;
const PET_FOX = 4;

const STAGE_EGG = 0;
const STAGE_BABY = 1;
const STAGE_TEEN = 2;
const STAGE_ADULT = 3;

const MOOD_IDLE = 0;
const MOOD_HAPPY = 1;
const MOOD_SAD = 2;
const MOOD_SLEEP = 3;
const MOOD_SICK = 4;
const MOOD_GHOST = 5;

const SLEEP_SECONDS = 3 * 3600;
const MAX_POOP = 4;

// Adult form, decided by how well the pet was cared for as it grew up.
const FORM_NEUTRAL = 0;
const FORM_RADIANT = 1;
const FORM_GRUMPY = 2;

// Inherited trait passed to the next generation; each eases one stat's decay.
const TRAIT_NONE = 0;
const TRAIT_HARDY = 1;      // health
const TRAIT_CHEERFUL = 2;   // happiness
const TRAIT_TIDY = 3;       // cleanliness
const TRAIT_ENERGETIC = 4;  // energy

class Pet {
    var petType = PET_CAT;
    var name = "Cat";
    var stage = STAGE_EGG;
    var hunger = 82.0;
    var happiness = 82.0;
    var energy = 82.0;
    var health = 90.0;
    var cleanliness = 82.0;
    var birthTime = 0;
    var lastUpdate = 0;
    var lastSteps = 0;
    var neglectScore = 0;
    var alive = true;
    var lastMessage = "Welcome!";
    var sleepUntil = 0;
    var poopCount = 0;
    var poopProgress = 0.0;
    var wakeGraceUntil = 0;
    var careScore = 50.0;
    var form = FORM_NEUTRAL;
    var trait = TRAIT_NONE;
    var generation = 1;

    function initialize() {
        var now = Time.now().value();
        birthTime = now;
        lastUpdate = now;
    }

    static function petTypeName(type as Number) as String {
        switch (type) {
            case PET_DOG: return "Dog";
            case PET_CAT: return "Cat";
            case PET_DRAGON: return "Dragon";
            case PET_PENGUIN: return "Penguin";
            case PET_FOX: return "Fox";
        }
        return "Pet";
    }

    function adopt(type as Number) as Void {
        var now = Time.now().value();
        petType = type;
        name = Pet.petTypeName(type);
        stage = STAGE_EGG;
        hunger = 86.0;
        happiness = 86.0;
        energy = 88.0;
        health = 92.0;
        cleanliness = 84.0;
        birthTime = now;
        lastUpdate = now;
        lastSteps = readSteps();
        neglectScore = 0;
        alive = true;
        sleepUntil = 0;
        poopCount = 0;
        poopProgress = 0.0;
        careScore = 50.0;
        form = FORM_NEUTRAL;
        trait = TRAIT_NONE;
        generation = 1;
        lastMessage = "A new friend!";
    }

    function updateFromClock() as Void {
        var now = Time.now().value();
        var elapsed = now - lastUpdate;
        if (elapsed < 60) {
            return;
        }

        var stepDelta = readStepDelta();

        // Split the elapsed window into the portion spent asleep and awake, so
        // decay slows (and energy recovers) only for the time the pet was
        // actually sleeping -- even if the app was closed across the wake time.
        var asleepSecs = 0;
        if (sleepUntil > lastUpdate) {
            var sleepEnd = (now < sleepUntil) ? now : sleepUntil;
            asleepSecs = sleepEnd - lastUpdate;
            if (asleepSecs < 0) { asleepSecs = 0; }
        }
        var awakeSecs = elapsed - asleepSecs;
        var asleepH = asleepSecs.toFloat() / 3600.0;
        var awakeH = awakeSecs.toFloat() / 3600.0;
        var hours = elapsed.toFloat() / 3600.0;

        // Awake decay: rates are per real-world hour, emptying over ~a day.
        // An inherited trait eases one stat's decay.
        var happyMul = (trait == TRAIT_CHEERFUL) ? 0.65 : 1.0;
        var cleanMul = (trait == TRAIT_TIDY) ? 0.65 : 1.0;
        var energyMul = (trait == TRAIT_ENERGETIC) ? 0.65 : 1.0;
        hunger -= awakeH * 3.2;
        cleanliness -= awakeH * 1.7 * cleanMul;
        happiness -= awakeH * 1.5 * happyMul;
        energy -= awakeH * 1.7 * energyMul;

        // Asleep: everything decays much slower and energy steadily recovers.
        hunger -= asleepH * 1.0;
        cleanliness -= asleepH * 0.6;
        happiness -= asleepH * 0.4;
        energy += asleepH * 12.0;

        // Activity bonuses only count while the pet is awake.
        if (awakeSecs > 0 && stepDelta > 0) {
            var stepBonus = minNum(15, stepDelta / 350);
            happiness += stepBonus;
            energy += minNum(8, stepDelta / 700);
            hunger -= minNum(12, stepDelta / 500);
        }

        if (awakeSecs > 0) {
            var hr = readHeartRate();
            if (hr != null) {
                if (hr > 110) {
                    happiness += 2;
                    energy -= 1;
                } else if (hr > 0 && hr < 55) {
                    energy += 1;
                }
            }
        }

        // Auto-wake once the sleep window has passed.
        if (sleepUntil != 0 && now >= sleepUntil) {
            sleepUntil = 0;
            lastMessage = "Good morning!";
        }

        // At night a tired pet nods off on its own (unless just woken).
        var clock = System.getClockTime();
        var night = (clock.hour >= 22 || clock.hour < 6);
        if (alive && stage != STAGE_EGG && sleepUntil == 0 && night && energy < 35 && now >= wakeGraceUntil) {
            sleepUntil = now + SLEEP_SECONDS;
            lastMessage = "Getting sleepy...";
        }

        // The pet poops over time (faster while awake). Each pile left on screen
        // keeps dragging cleanliness down until it is cleaned up.
        poopProgress += awakeH * 0.45 + asleepH * 0.1;
        while (poopProgress >= 1.0 && poopCount < MAX_POOP) {
            poopCount += 1;
            poopProgress -= 1.0;
        }
        if (poopProgress > 1.0) {
            poopProgress = 1.0;
        }
        if (poopCount > 0) {
            cleanliness -= hours * poopCount * 1.6;
        }

        clampAll();
        updateStage(now);
        updateHealth(hours);
        updateNeglect(hours);

        // Lifelong care quality slowly tracks the running stat average; it
        // decides the adult form.
        var blend = hours * 0.08;
        if (blend > 1.0) { blend = 1.0; }
        careScore += (averageStats() - careScore) * blend;
        if (careScore < 0) { careScore = 0.0; }
        if (careScore > 100) { careScore = 100.0; }

        lastUpdate = now;
    }

    function feed() as String {
        if (!alive) { return revive(); }
        hunger += 28;
        happiness += 4;
        cleanliness -= 5;
        poopProgress += 0.35;   // what goes in must come out
        clampAll();
        lastMessage = "Yum!";
        return lastMessage;
    }

    function hatch() as String {
        if (!alive) { return revive(); }
        if (stage == STAGE_EGG) {
            stage = STAGE_BABY;
            birthTime = Time.now().value() - (2 * 3600);
            happiness += 8;
            energy += 5;
            clampAll();
            lastMessage = "Hatched!";
            return lastMessage;
        }
        return feed();
    }

    function play() as String {
        if (!alive) { return revive(); }
        happiness += 25;
        energy -= 12;
        hunger -= 9;
        cleanliness -= 4;
        clampAll();
        lastMessage = "That was fun!";
        return lastMessage;
    }

    // Result of the Play mini-game: happiness scales with the catch score.
    function playResult(score as Number, rounds as Number) as String {
        if (!alive) { return revive(); }
        happiness += 8 + score * 6;
        energy -= 12;
        hunger -= 9;
        cleanliness -= 4;
        poopProgress += 0.1;
        clampAll();
        lastMessage = "Played! " + score + "/" + rounds;
        return lastMessage;
    }

    function clean() as String {
        if (!alive) { return revive(); }
        cleanliness += 35;
        health += 6;
        happiness += 2;
        poopCount = 0;
        poopProgress = 0.0;
        clampAll();
        lastMessage = "All clean!";
        return lastMessage;
    }

    // Sick when health is low; Medicine is the cure.
    function isSick() as Boolean {
        return alive && health < 30;
    }

    function medicine() as String {
        if (!alive) { return revive(); }
        health += 32;
        happiness -= 3;
        clampAll();
        lastMessage = isSick() ? "Bitter, but helps." : "Feeling better!";
        return lastMessage;
    }

    // Put the pet down for a multi-hour sleep. Energy recovers gradually over
    // the sleep window (see updateFromClock) rather than all at once.
    function sleep() as String {
        if (!alive) { return revive(); }
        sleepUntil = Time.now().value() + SLEEP_SECONDS;
        lastMessage = "Goodnight...";
        return lastMessage;
    }

    function wake() as String {
        sleepUntil = 0;
        // Don't let auto-sleep drag it straight back to bed for a while.
        wakeGraceUntil = Time.now().value() + 1800;
        lastMessage = "Good morning!";
        return lastMessage;
    }

    function isSleeping() as Boolean {
        return alive && sleepUntil != 0 && Time.now().value() < sleepUntil;
    }

    function discipline() as String {
        if (!alive) { return revive(); }
        happiness -= 5;
        health += 4;
        neglectScore = maxNum(0, neglectScore - 10);
        clampAll();
        lastMessage = "Focused.";
        return lastMessage;
    }

    function revive() as String {
        alive = true;
        stage = STAGE_BABY;
        hunger = 70.0;
        happiness = 72.0;
        energy = 72.0;
        health = 74.0;
        cleanliness = 72.0;
        neglectScore = 0;
        sleepUntil = 0;
        poopCount = 0;
        poopProgress = 0.0;
        lastUpdate = Time.now().value();
        lastMessage = "Revived!";
        return lastMessage;
    }

    function mood() as Number {
        if (!alive) { return MOOD_GHOST; }
        if (isSleeping()) { return MOOD_SLEEP; }
        if (health < 30) { return MOOD_SICK; }
        if (energy < 20) { return MOOD_SLEEP; }
        if (hunger < 25 || happiness < 25 || cleanliness < 25) { return MOOD_SAD; }
        if (happiness > 75 && health > 60) { return MOOD_HAPPY; }
        return MOOD_IDLE;
    }

    function primaryNeed() as String {
        if (!alive) { return "Tap to revive"; }
        var low = minNum(minNum(hunger, happiness), minNum(energy, minNum(health, cleanliness)));
        if (low == hunger) { return "Hungry"; }
        if (low == happiness) { return "Needs play"; }
        if (low == energy) { return "Sleepy"; }
        if (low == health) { return "Unwell"; }
        return "Messy";
    }

    function averageStats() as Number {
        return ((hunger + happiness + energy + health + cleanliness) / 5.0).toNumber();
    }

    function updateStage(now as Number) as Void {
        var prev = stage;
        var ageHours = (now - birthTime) / 3600;
        if (ageHours >= 72) {
            stage = STAGE_ADULT;
        } else if (ageHours >= 24) {
            stage = STAGE_TEEN;
        } else if (ageHours >= 2) {
            stage = STAGE_BABY;
        } else {
            stage = STAGE_EGG;
        }
        // Growing into an adult locks in the form earned through care.
        if (prev != STAGE_ADULT && stage == STAGE_ADULT) {
            if (careScore >= 66) {
                form = FORM_RADIANT;
            } else if (careScore <= 33) {
                form = FORM_GRUMPY;
            } else {
                form = FORM_NEUTRAL;
            }
            lastMessage = "Grew up!";
        }
    }

    function updateHealth(hours as Float) as Void {
        var penalty = 0;
        if (hunger < 15) { penalty += 2; }
        if (cleanliness < 15) { penalty += 2; }
        if (energy < 10) { penalty += 1; }
        if (happiness < 10) { penalty += 1; }
        // Hardy pets resist health loss and heal a little faster.
        var hardy = (trait == TRAIT_HARDY);
        if (penalty > 0) {
            health -= hours * penalty * (hardy ? 0.6 : 1.0);
        } else if (health < 100) {
            health += hours * (hardy ? 2.2 : 1.5);
        }
        clampAll();
    }

    function updateNeglect(hours as Float) as Void {
        if (averageStats() < 20) {
            neglectScore += hours * 6.0;
        } else {
            neglectScore = maxNum(0.0, neglectScore - hours * 4.0);
        }

        if (health <= 0 || neglectScore >= 100) {
            alive = false;
            lastMessage = "Passed on... tap for legacy";
        }
    }

    // Start the next generation: a fresh egg of the same species that inherits a
    // trait earned by how well the previous pet was raised.
    function beginLegacy() as String {
        var inherited = traitFromCare();
        var nextGen = generation + 1;
        var species = petType;
        adopt(species);          // resets to a fresh egg (generation -> 1)
        generation = nextGen;
        trait = inherited;
        lastMessage = "Gen " + nextGen + " * " + traitName(inherited);
        return lastMessage;
    }

    function traitFromCare() as Number {
        if (careScore >= 66) { return TRAIT_HARDY; }
        if (careScore >= 50) { return TRAIT_CHEERFUL; }
        if (careScore >= 34) { return TRAIT_TIDY; }
        return TRAIT_ENERGETIC;
    }

    static function traitName(t as Number) as String {
        switch (t) {
            case TRAIT_HARDY: return "Hardy";
            case TRAIT_CHEERFUL: return "Cheerful";
            case TRAIT_TIDY: return "Tidy";
            case TRAIT_ENERGETIC: return "Energetic";
        }
        return "None";
    }

    function formSymbol() as String {
        if (stage != STAGE_ADULT) { return ""; }
        if (form == FORM_RADIANT) { return " *"; }
        if (form == FORM_GRUMPY) { return " ~"; }
        return "";
    }

    // Whole days the pet has lived.
    function ageDays() as Number {
        return (Time.now().value() - birthTime) / 86400;
    }

    function readSteps() as Number {
        try {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                return info.steps;
            }
        } catch (ex) {
        }
        return 0;
    }

    function readStepDelta() as Number {
        var steps = readSteps();
        var delta = steps - lastSteps;
        if (delta < 0) {
            delta = 0;
        }
        lastSteps = steps;
        return delta;
    }

    function readHeartRate() {
        try {
            var info = Sensor.getInfo();
            if (info != null && info.heartRate != null) {
                return info.heartRate;
            }
        } catch (ex) {
        }
        return null;
    }

    function clampAll() as Void {
        hunger = clamp(hunger);
        happiness = clamp(happiness);
        energy = clamp(energy);
        health = clamp(health);
        cleanliness = clamp(cleanliness);
    }

    function clamp(value as Numeric) as Numeric {
        return maxNum(0, minNum(100, value));
    }

    function minNum(a as Numeric, b as Numeric) as Numeric {
        return (a < b) ? a : b;
    }

    function maxNum(a as Numeric, b as Numeric) as Numeric {
        return (a > b) ? a : b;
    }
}
