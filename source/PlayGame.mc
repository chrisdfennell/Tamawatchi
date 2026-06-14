import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// A quick "catch the ball" reflex game. A marker slides back and forth along a
// track; press START while it's over the green target zone to score. After a
// few rounds the happiness reward is applied (scaled by score).
class PlayGameView extends WatchUi.View {
    var pet as Pet;
    var gameTimer;
    var pos = 0;
    var dir = 1;
    var speed = 4;
    var round = 0;
    var rounds = 5;
    var score = 0;
    var done = false;

    function initialize(model as Pet) {
        View.initialize();
        pet = model;
    }

    function onShow() as Void {
        if (gameTimer == null) {
            gameTimer = new Timer.Timer();
            gameTimer.start(method(:onGameTick), 60, true);
        }
    }

    function onHide() as Void {
        if (gameTimer != null) {
            gameTimer.stop();
            gameTimer = null;
        }
    }

    function onGameTick() as Void {
        if (done) {
            return;
        }
        pos += dir * speed;
        if (pos <= 0) { pos = 0; dir = 1; }
        if (pos >= 100) { pos = 100; dir = -1; }
        WatchUi.requestUpdate();
    }

    // Returns true if the press was consumed by the game (still playing).
    function attempt() as Boolean {
        if (done) {
            return false;
        }
        if (pos >= 38 && pos <= 62) {
            score += 1;
        }
        round += 1;
        speed += 1;
        if (round >= rounds) {
            finish();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function finish() as Void {
        done = true;
        if (gameTimer != null) {
            gameTimer.stop();
            gameTimer = null;
        }
        pet.playResult(score, rounds);
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x10243A, 0x10243A);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (done) {
            dc.drawText(w / 2, (h * 28) / 100, Graphics.FONT_SMALL, "Nice!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 44) / 100, Graphics.FONT_NUMBER_MEDIUM, score + "/" + rounds, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 70) / 100, Graphics.FONT_TINY, "Press to finish", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.drawText(w / 2, (h * 16) / 100, Graphics.FONT_SMALL, "Catch the ball!", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 30) / 100, Graphics.FONT_TINY, "Round " + (round + 1) + "/" + rounds + "   Score " + score, Graphics.TEXT_JUSTIFY_CENTER);

        var trackX = (w * 15) / 100;
        var trackW = (w * 70) / 100;
        var trackY = h / 2 + 8;

        // Track
        dc.setColor(0x2B3A52, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(trackX, trackY, trackW, 10, 5);
        // Target zone (center)
        var zoneX = trackX + (trackW * 38) / 100;
        var zoneW = (trackW * 24) / 100;
        dc.setColor(0x73E09B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(zoneX, trackY, zoneW, 10, 5);
        // Marker (the ball)
        var mx = trackX + (trackW * pos) / 100;
        dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mx, trackY + 5, 9);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mx - 3, trackY + 2, 2);

        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 78) / 100, Graphics.FONT_TINY, "Press in the green!", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class PlayGameDelegate extends WatchUi.BehaviorDelegate {
    var game as PlayGameView;

    function initialize(gameRef as PlayGameView) {
        BehaviorDelegate.initialize();
        game = gameRef;
    }

    function onSelect() as Boolean {
        if (game.done) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            game.attempt();
        }
        return true;
    }

    function onTap(evt as ClickEvent) as Boolean {
        return onSelect();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
