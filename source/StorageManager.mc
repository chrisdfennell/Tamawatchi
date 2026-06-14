import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

const KEY_VERSION = "stateVersion";
const KEY_PET_TYPE = "petType";
const KEY_NAME = "petName";
const KEY_STAGE = "stage";
const KEY_HUNGER = "hunger";
const KEY_HAPPINESS = "happiness";
const KEY_ENERGY = "energy";
const KEY_HEALTH = "health";
const KEY_CLEANLINESS = "cleanliness";
const KEY_BIRTH = "birthTime";
const KEY_LAST_UPDATE = "lastUpdate";
const KEY_LAST_STEPS = "lastSteps";
const KEY_NEGLECT = "neglectScore";
const KEY_ALIVE = "alive";
const KEY_SLEEP = "sleepUntil";
const KEY_POOP = "poopCount";
const KEY_POOPPROG = "poopProgress";
const KEY_CARE = "careScore";
const KEY_FORM = "form";
const KEY_TRAIT = "trait";
const KEY_GEN = "generation";
const KEY_CHOSEN = "hasChosenPet";
const KEY_HELP_SEEN = "helpSeen";
const KEY_VIBES = "vibesEnabled";

class StorageManager {
    static function hasPet() as Boolean {
        return Application.Storage.getValue(KEY_CHOSEN) == true;
    }

    static function markChosen() as Void {
        Application.Storage.setValue(KEY_CHOSEN, true);
        Application.Storage.setValue(KEY_VERSION, 1);
    }

    static function hasSeenHelp() as Boolean {
        return Application.Storage.getValue(KEY_HELP_SEEN) == true;
    }

    static function markHelpSeen() as Void {
        Application.Storage.setValue(KEY_HELP_SEEN, true);
    }

    static function vibesEnabled() as Boolean {
        // Vibration prompts are on unless the user turns them off in Settings.
        return Application.Storage.getValue(KEY_VIBES) != false;
    }

    static function setVibes(enabled as Boolean) as Void {
        Application.Storage.setValue(KEY_VIBES, enabled);
    }

    static function resetAll() as Void {
        Application.Storage.clearValues();
    }

    static function getNumber(key as String, fallback as Number) as Number {
        var value = Application.Storage.getValue(key);
        return (value == null) ? fallback : value;
    }

    static function getString(key as String, fallback as String) as String {
        var value = Application.Storage.getValue(key);
        return (value == null) ? fallback : value;
    }

    static function getBoolean(key as String, fallback as Boolean) as Boolean {
        var value = Application.Storage.getValue(key);
        return (value == null) ? fallback : value;
    }

    static function savePet(pet as Pet) as Void {
        Application.Storage.setValue(KEY_PET_TYPE, pet.petType);
        Application.Storage.setValue(KEY_NAME, pet.name);
        Application.Storage.setValue(KEY_STAGE, pet.stage);
        Application.Storage.setValue(KEY_HUNGER, pet.hunger);
        Application.Storage.setValue(KEY_HAPPINESS, pet.happiness);
        Application.Storage.setValue(KEY_ENERGY, pet.energy);
        Application.Storage.setValue(KEY_HEALTH, pet.health);
        Application.Storage.setValue(KEY_CLEANLINESS, pet.cleanliness);
        Application.Storage.setValue(KEY_BIRTH, pet.birthTime);
        Application.Storage.setValue(KEY_LAST_UPDATE, pet.lastUpdate);
        Application.Storage.setValue(KEY_LAST_STEPS, pet.lastSteps);
        Application.Storage.setValue(KEY_NEGLECT, pet.neglectScore);
        Application.Storage.setValue(KEY_ALIVE, pet.alive);
        Application.Storage.setValue(KEY_SLEEP, pet.sleepUntil);
        Application.Storage.setValue(KEY_POOP, pet.poopCount);
        Application.Storage.setValue(KEY_POOPPROG, pet.poopProgress);
        Application.Storage.setValue(KEY_CARE, pet.careScore);
        Application.Storage.setValue(KEY_FORM, pet.form);
        Application.Storage.setValue(KEY_TRAIT, pet.trait);
        Application.Storage.setValue(KEY_GEN, pet.generation);
        markChosen();
    }

    static function loadPet() as Pet {
        var pet = new Pet();
        pet.petType = getNumber(KEY_PET_TYPE, PET_CAT);
        pet.name = getString(KEY_NAME, Pet.petTypeName(pet.petType));
        pet.stage = getNumber(KEY_STAGE, STAGE_EGG);
        pet.hunger = getNumber(KEY_HUNGER, 82);
        pet.happiness = getNumber(KEY_HAPPINESS, 82);
        pet.energy = getNumber(KEY_ENERGY, 82);
        pet.health = getNumber(KEY_HEALTH, 90);
        pet.cleanliness = getNumber(KEY_CLEANLINESS, 82);
        pet.birthTime = getNumber(KEY_BIRTH, Time.now().value());
        pet.lastUpdate = getNumber(KEY_LAST_UPDATE, Time.now().value());
        pet.lastSteps = getNumber(KEY_LAST_STEPS, 0);
        pet.neglectScore = getNumber(KEY_NEGLECT, 0);
        pet.alive = getBoolean(KEY_ALIVE, true);
        pet.sleepUntil = getNumber(KEY_SLEEP, 0);
        pet.poopCount = getNumber(KEY_POOP, 0);
        pet.poopProgress = getNumber(KEY_POOPPROG, 0);
        pet.careScore = getNumber(KEY_CARE, 50);
        pet.form = getNumber(KEY_FORM, FORM_NEUTRAL);
        pet.trait = getNumber(KEY_TRAIT, TRAIT_NONE);
        pet.generation = getNumber(KEY_GEN, 1);
        return pet;
    }
}
