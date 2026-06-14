import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class TamagotchiApp extends Application.AppBase {
    var pet;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) as Void {
        System.println("Garmi-gotchi onStart");
        pet = StorageManager.hasPet() ? StorageManager.loadPet() : new Pet();
        applyCustomName(pet);
        pet.updateFromClock();
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    // A non-empty custom name typed in the Garmin Connect app overrides the
    // in-app chosen name.
    function applyCustomName(p) as Void {
        try {
            var custom = Application.Properties.getValue("petName");
            if (custom != null && custom instanceof Lang.String && custom.length() > 0) {
                p.name = custom;
            }
        } catch (ex) {
        }
    }

    function onSettingsChanged() as Void {
        if (pet != null) {
            applyCustomName(pet);
            StorageManager.savePet(pet);
            PetComplication.publish(pet);
            WatchUi.requestUpdate();
        }
    }

    function onStop(state) as Void {
        System.println("Garmi-gotchi onStop");
        if (pet != null) {
            pet.updateFromClock();
            StorageManager.savePet(pet);
            PetComplication.publish(pet);
        }
    }

    function getInitialView() {
        System.println("Garmi-gotchi getInitialView");
        if (pet == null) {
            pet = StorageManager.hasPet() ? StorageManager.loadPet() : new Pet();
        }
        var view = new TamagotchiView(pet);
        return [ view, new TamagotchiInputDelegate(view, pet) ];
    }

    // The glance is the always-one-swipe-away ambient surface: it advances the
    // pet from the clock, persists it, and republishes the complication so the
    // value on the user's watch face stays fresh whenever the glance is shown.
    function getGlanceView() {
        if (pet == null) {
            pet = StorageManager.hasPet() ? StorageManager.loadPet() : new Pet();
        }
        pet.updateFromClock();
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
        return [ new TamagotchiGlanceView(pet) ];
    }

    function maybeNotify() as Void {
        if (pet == null || !pet.alive) {
            return;
        }

        var need = pet.primaryNeed();
        var messy = (need == "Messy" && pet.isMessy());
        if ((need == "Hungry" || need == "Needs play" || messy) && StorageManager.vibesEnabled()) {
            try {
                Attention.vibrate([ new Attention.VibeProfile(50, 120) ]);
            } catch (ex) {
            }
        }
    }
}

function getApp() as TamagotchiApp {
    return Application.getApp() as TamagotchiApp;
}
