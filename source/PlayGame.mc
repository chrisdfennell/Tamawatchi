import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Play launches one of several quick mini-games at random, so it stays fresh.
// Each game applies a happiness reward (scaled by score) via pet.playResult().

function randomInt(n as Number) as Number {
    var r = Math.rand();
    if (r < 0) { r = -r; }
    return r % n;
}

function pushRandomMiniGame(pet as Pet) as Void {
    var pick = randomInt(3);
    var view;
    var delegate;
    if (pick == 0) {
        view = new CatchGameView(pet);
        delegate = new MiniGameDelegate(view);
    } else if (pick == 1) {
        view = new ReflexGameView(pet);
        delegate = new MiniGameDelegate(view);
    } else {
        view = new MashGameView(pet);
        delegate = new MiniGameDelegate(view);
    }
    WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
}

// Shared input delegate: a press attempts the game; once finished, a press exits.
class MiniGameDelegate extends WatchUi.BehaviorDelegate {
    var game;

    function initialize(gameRef) {
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

// ── Game 1: Catch the ball ─────────────────────────────────────────────────
// A marker slides along a track; press while it's over the green target zone.
class CatchGameView extends WatchUi.View {
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
        stop();
    }

    function stop() as Void {
        if (gameTimer != null) {
            gameTimer.stop();
            gameTimer = null;
        }
    }

    function onGameTick() as Void {
        if (done) { return; }
        pos += dir * speed;
        if (pos <= 0) { pos = 0; dir = 1; }
        if (pos >= 100) { pos = 100; dir = -1; }
        WatchUi.requestUpdate();
    }

    function attempt() as Void {
        if (done) { return; }
        if (pos >= 38 && pos <= 62) { score += 1; }
        round += 1;
        speed += 1;
        if (round >= rounds) { finish(); }
        WatchUi.requestUpdate();
    }

    function finish() as Void {
        done = true;
        stop();
        pet.playResult(score, rounds);
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x10243A, 0x10243A);
        dc.clear();
        if (done) {
            drawResult(dc, w, h, "Nice!", score + "/" + rounds);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 16) / 100, Graphics.FONT_SMALL, "Catch the ball!", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 30) / 100, Graphics.FONT_TINY, "Round " + (round + 1) + "/" + rounds + "   Score " + score, Graphics.TEXT_JUSTIFY_CENTER);

        var trackX = (w * 15) / 100;
        var trackW = (w * 70) / 100;
        var trackY = h / 2 + 8;
        dc.setColor(0x2B3A52, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(trackX, trackY, trackW, 10, 5);
        var zoneX = trackX + (trackW * 38) / 100;
        dc.setColor(0x73E09B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(zoneX, trackY, (trackW * 24) / 100, 10, 5);
        var mx = trackX + (trackW * pos) / 100;
        dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mx, trackY + 5, 9);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mx - 3, trackY + 2, 2);

        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 78) / 100, Graphics.FONT_TINY, "Press in the green!", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

// ── Game 2: Reaction test ──────────────────────────────────────────────────
// Wait for the circle to turn green, then press as fast as you can.
class ReflexGameView extends WatchUi.View {
    var pet as Pet;
    var gameTimer;
    var round = 0;
    var rounds = 4;
    var score = 0;
    var green = false;
    var greenAt = 0;
    var result = "";
    var done = false;

    function initialize(model as Pet) {
        View.initialize();
        pet = model;
    }

    function onShow() as Void {
        if (gameTimer == null) {
            gameTimer = new Timer.Timer();
            gameTimer.start(method(:onGameTick), 50, true);
        }
        beginRound();
    }

    function onHide() as Void {
        stop();
    }

    function stop() as Void {
        if (gameTimer != null) {
            gameTimer.stop();
            gameTimer = null;
        }
    }

    function beginRound() as Void {
        if (round >= rounds) {
            finish();
            return;
        }
        green = false;
        greenAt = System.getTimer() + 700 + randomInt(2000);
        WatchUi.requestUpdate();
    }

    function onGameTick() as Void {
        if (done || green) { return; }
        if (System.getTimer() >= greenAt) {
            green = true;
            WatchUi.requestUpdate();
        }
    }

    function attempt() as Void {
        if (done) { return; }
        if (green) {
            score += 1;
            result = "Good!";
        } else {
            result = "Too early!";
        }
        round += 1;
        if (round >= rounds) {
            finish();
        } else {
            beginRound();
        }
        WatchUi.requestUpdate();
    }

    function finish() as Void {
        done = true;
        stop();
        pet.playResult(score, rounds);
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x10243A, 0x10243A);
        dc.clear();
        if (done) {
            drawResult(dc, w, h, "Sharp!", score + "/" + rounds);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 15) / 100, Graphics.FONT_SMALL, "Reaction!", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 28) / 100, Graphics.FONT_TINY, "Round " + (round + 1) + "/" + rounds + "   Score " + score, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(green ? 0x73E09B : 0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w / 2, h / 2 + 6, (w * 22) / 100);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 + 6, Graphics.FONT_SMALL, green ? "TAP!" : "wait", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (!result.equals("")) {
            dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 82) / 100, Graphics.FONT_TINY, result, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

// ── Game 3: Button masher ──────────────────────────────────────────────────
// Tap as fast as you can before the timer runs out.
class MashGameView extends WatchUi.View {
    var pet as Pet;
    var gameTimer;
    var taps = 0;
    var endAt = 0;
    var done = false;
    const DURATION = 5000;

    function initialize(model as Pet) {
        View.initialize();
        pet = model;
    }

    function onShow() as Void {
        if (gameTimer == null) {
            endAt = System.getTimer() + DURATION;
            gameTimer = new Timer.Timer();
            gameTimer.start(method(:onGameTick), 100, true);
        }
    }

    function onHide() as Void {
        stop();
    }

    function stop() as Void {
        if (gameTimer != null) {
            gameTimer.stop();
            gameTimer = null;
        }
    }

    function onGameTick() as Void {
        if (done) { return; }
        if (System.getTimer() >= endAt) {
            finish();
        } else {
            WatchUi.requestUpdate();
        }
    }

    function attempt() as Void {
        if (done) { return; }
        taps += 1;
        WatchUi.requestUpdate();
    }

    function finish() as Void {
        done = true;
        stop();
        var score = taps / 6;
        if (score > 5) { score = 5; }
        pet.playResult(score, 5);
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x10243A, 0x10243A);
        dc.clear();
        if (done) {
            drawResult(dc, w, h, "Whew!", taps + " taps");
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 16) / 100, Graphics.FONT_SMALL, "Mash START!", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 - 4, Graphics.FONT_NUMBER_MEDIUM, taps.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Time remaining bar
        var remain = endAt - System.getTimer();
        if (remain < 0) { remain = 0; }
        var barX = (w * 18) / 100;
        var barW = (w * 64) / 100;
        var barY = (h * 74) / 100;
        dc.setColor(0x2B3A52, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, 10, 5);
        dc.setColor(0x4CAAE8, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, (barW * remain) / DURATION, 10, 5);
    }
}

// Shared end screen for all mini-games.
function drawResult(dc as Dc, w as Number, h as Number, title as String, value as String) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, (h * 28) / 100, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
    dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, (h * 46) / 100, Graphics.FONT_NUMBER_MEDIUM, value, Graphics.TEXT_JUSTIFY_CENTER);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, (h * 72) / 100, Graphics.FONT_TINY, "Press to finish", Graphics.TEXT_JUSTIFY_CENTER);
}
