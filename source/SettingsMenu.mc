import Toybox.Lang;
import Toybox.WatchUi;

// Long-press Settings menu: toggle vibration, change pet, or reset the game.
function buildSettingsMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({ :title => "Settings" });
    menu.addItem(new WatchUi.ToggleMenuItem(
        "Vibration",
        { :enabled => "On", :disabled => "Off" },
        :vibes,
        StorageManager.vibesEnabled(),
        null));
    menu.addItem(new WatchUi.MenuItem("Change Pet", "New friend", :changePet, null));
    menu.addItem(new WatchUi.MenuItem("Reset Game", "Start over", :reset, null));
    return menu;
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mainView as TamagotchiView;

    function initialize(view as TamagotchiView) {
        Menu2InputDelegate.initialize();
        mainView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :vibes) {
            StorageManager.setVibes((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :changePet) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.pushView(
                new WatchUi.Confirmation("Change pet? This replaces your current pet."),
                new GameConfirmDelegate(mainView, :changePet),
                WatchUi.SLIDE_UP);
        } else if (id == :reset) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.pushView(
                new WatchUi.Confirmation("Reset the game and lose your pet?"),
                new GameConfirmDelegate(mainView, :reset),
                WatchUi.SLIDE_UP);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class GameConfirmDelegate extends WatchUi.ConfirmationDelegate {
    var mainView as TamagotchiView;
    var mode as Symbol;

    function initialize(view as TamagotchiView, modeSym as Symbol) {
        ConfirmationDelegate.initialize();
        mainView = view;
        mode = modeSym;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            if (mode == :reset) {
                mainView.resetGame();
            } else {
                mainView.startChangePet();
            }
        }
        return true;
    }
}
