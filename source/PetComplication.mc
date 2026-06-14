import Toybox.Complications;
import Toybox.Lang;

// Publishes the pet's wellbeing as a Connect IQ complication so it can be shown
// on the user's watch face (publisher id 0, defined in complications.xml).
// All calls are guarded: devices without complication support simply skip.
class PetComplication {
    static const PET_MOOD_ID = 0;

    static function publish(pet as Pet) as Void {
        if (!(Toybox has :Complications)) {
            return;
        }
        try {
            Complications.updateComplication(PET_MOOD_ID, {
                :value => pet.averageStats(),
                :shortLabel => moodLabel(pet)
            });
        } catch (ex) {
        }
    }

    // Five-character (max) summary shown on radial complications.
    static function moodLabel(pet as Pet) as String {
        if (!pet.alive) {
            return "RIP";
        }
        switch (pet.mood()) {
            case MOOD_SICK: return "SICK";
            case MOOD_SLEEP: return "ZZZ";
            case MOOD_SAD: return "SAD";
            case MOOD_HAPPY: return "HAPPY";
        }
        return "OK";
    }
}
