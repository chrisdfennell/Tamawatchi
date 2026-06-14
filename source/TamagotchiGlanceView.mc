import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class TamagotchiGlanceView extends WatchUi.GlanceView {
    var pet as Pet;

    function initialize(model as Pet) {
        GlanceView.initialize();
        pet = model;
    }

    function onUpdate(dc as Dc) as Void {
        pet.updateFromClock();
        StorageManager.savePet(pet);
        PetComplication.publish(pet);

        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x0B0D12, 0x0B0D12);
        dc.clear();

        var avg = pet.averageStats();
        var color = avg > 66 ? 0x73E09B : (avg > 34 ? 0xFFDD55 : 0xDA3741);

        // The system draws the app icon at the left of the glance, so keep all
        // text/bars clear of that zone. The title uses the largest font that
        // still fits the available width (so "Garmi-gotchi" is never clipped),
        // and the rows stack by real font height so nothing overlaps.
        var left = 50;
        var right = 6;
        var contentW = w - left - right;
        if (contentW > 160) {
            contentW = 160;
        }

        var title = "Garmi-gotchi";
        var titleFont = Graphics.FONT_XTINY;
        var candidates = [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        for (var i = 0; i < candidates.size(); i++) {
            if (dc.getTextWidthInPixels(title, candidates[i]) <= contentW) {
                titleFont = candidates[i];
                break;
            }
        }

        var bodyFont = Graphics.FONT_XTINY;
        var th = dc.getFontHeight(titleFont);
        var bh = dc.getFontHeight(bodyFont);
        var barH = 8;
        var gap = 3;

        // Use a 3-row layout (title / need + score / bar) when it fits the
        // glance height; otherwise fall back to title + bar with score inline.
        var threeRows = th + gap + bh + gap + barH;
        var showStatusRow = (threeRows <= h);
        var blockH = showStatusRow ? threeRows : (th + gap + barH);
        var y = (h - blockH) / 2;
        if (y < 0) {
            y = 0;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y, titleFont, title, Graphics.TEXT_JUSTIFY_LEFT);

        var bary;
        var scoreText = avg.format("%d");
        if (showStatusRow) {
            var by = y + th + gap;
            var status = statusText();
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left, by, bodyFont, status, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(left + contentW, by, bodyFont, scoreText, Graphics.TEXT_JUSTIFY_RIGHT);
            bary = by + bh + gap;
        } else {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + contentW, y, bodyFont, scoreText, Graphics.TEXT_JUSTIFY_RIGHT);
            bary = y + th + gap;
        }

        dc.setColor(0x2B2227, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(left, bary, contentW, barH);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(left + 1, bary + 1, ((contentW - 2) * avg) / 100, barH - 2);
    }

    // Summarise everything that needs attention, not just the single lowest
    // stat. Shows up to two needs (+ a "+" when there are more), or a positive
    // status when the pet is content.
    function statusText() as String {
        if (!pet.alive) { return "Needs you!"; }
        if (pet.isSleeping()) { return "Sleeping..."; }

        var needs = [] as Array<String>;
        if (pet.hunger < 40) { needs.add("Hungry"); }
        if (pet.happiness < 40) { needs.add("Bored"); }
        if (pet.energy < 40) { needs.add("Sleepy"); }
        if (pet.health < 40) { needs.add("Sick"); }
        if (pet.isMessy()) { needs.add("Messy"); }

        if (needs.size() == 0) {
            return (pet.averageStats() > 75) ? "Thriving!" : "Content";
        }

        var s = needs[0];
        if (needs.size() > 1) { s += " - " + needs[1]; }
        if (needs.size() > 2) { s += " +"; }
        return s;
    }
}
