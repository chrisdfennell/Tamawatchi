import Toybox.Lang;
import Toybox.WatchUi;

// The Care menu opened with START on the pet page.
function buildCareMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({ :title => "Tap to Care" });
    menu.addItem(new WatchUi.MenuItem("Feed", "Eases hunger", :feed, null));
    menu.addItem(new WatchUi.MenuItem("Play", "Lifts mood", :play, null));
    menu.addItem(new WatchUi.MenuItem("Clean", "Tidies up", :clean, null));
    menu.addItem(new WatchUi.MenuItem("Sleep", "Naps ~3h", :sleep, null));
    menu.addItem(new WatchUi.MenuItem("Medicine", "Heals sickness", :medicine, null));
    menu.addItem(new WatchUi.MenuItem("Discipline", "Calms & heals", :discipline, null));
    return menu;
}

class CareMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mainView as TamagotchiView;

    function initialize(view as TamagotchiView) {
        Menu2InputDelegate.initialize();
        mainView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (id == :play) {
            // Play launches a random mini-game.
            if (mainView.pet.alive && mainView.pet.stage != STAGE_EGG && !mainView.pet.isSleeping()) {
                pushRandomMiniGame(mainView.pet);
            }
        } else {
            mainView.performCare(id as Symbol);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
