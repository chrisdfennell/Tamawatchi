import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class TamawatchiView extends WatchUi.View {
    const SCREEN_PET = 0;
    const SCREEN_STATS = 1;

    const ANIM_INTERVAL = 220;

    var pet as Pet;
    var timer;
    var frame = 0;
    var screen = SCREEN_PET;
    var choosingPet = false;
    var selectedPetType = PET_CAT;
    var lastPromptTime = 0;
    var showingHelp = false;
    var animType = null;
    var animStep = 0;
    var animMax = 0;
    var animTimer = null;

    // loadResource() decodes a PNG from flash on every call, which is far too
    // expensive to run on each 1 Hz / animation redraw. Keep the most recently
    // shown sprite and only reload when the requested drawable actually changes.
    var spriteCache = null;
    var spriteCacheId = null;

    function initialize(model as Pet) {
        View.initialize();
        pet = model;
        choosingPet = !StorageManager.hasPet();
        showingHelp = !choosingPet && !StorageManager.hasSeenHelp();
    }

    function onShow() as Void {
        System.println("Tamawatchi view onShow");
        pet.updateFromClock();
        startTimer();
    }

    function onHide() as Void {
        stopTimer();
        stopAnim();
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
    }

    function onUpdate(dc as Dc) as Void {
        pet.updateFromClock();
        drawBackground(dc);
        if (choosingPet) {
            drawPetChooser(dc);
        } else if (showingHelp) {
            drawHelp(dc);
        } else if (animType != null) {
            drawActionAnim(dc);
        } else if (screen == SCREEN_STATS) {
            drawStatsScreen(dc);
        } else {
            drawPetScreen(dc);
        }
    }

    function startTimer() as Void {
        if (timer == null) {
            timer = new Timer.Timer();
            timer.start(method(:onTick), 1000, true);
        }
    }

    function stopTimer() as Void {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function onTick() as Void {
        frame = (frame + 1) % 4;
        maybePrompt();
        WatchUi.requestUpdate();
    }

    function maybePrompt() as Void {
        if (pet.isSleeping()) {
            return;
        }
        var now = Time.now().value();
        if (lastPromptTime != 0 && (now - lastPromptTime) < 600) {
            return;
        }

        var need = pet.primaryNeed();
        if (need == "Hungry") {
            pet.lastMessage = "Hungry! Walk or feed.";
        } else if (need == "Needs play") {
            pet.lastMessage = "Play time?";
        } else if (need == "Messy" && pet.isMessy()) {
            pet.lastMessage = "Clean up time.";
        } else if (!pet.alive) {
            pet.lastMessage = "Select to revive.";
        } else {
            return;
        }

        lastPromptTime = now;
        if (StorageManager.vibesEnabled()) {
            try {
                Attention.vibrate([ new Attention.VibeProfile(35, 80) ]);
            } catch (ex) {
            }
        }
    }

    function nextPet() as Void {
        selectedPetType = (selectedPetType + 1) % 5;
        WatchUi.requestUpdate();
    }

    function previousPet() as Void {
        selectedPetType = (selectedPetType + 4) % 5;
        WatchUi.requestUpdate();
    }

    function choosePet() as Void {
        pet.adopt(selectedPetType);
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
        choosingPet = false;
        WatchUi.pushView(buildNameMenu(pet), new NameMenuDelegate(self), WatchUi.SLIDE_UP);
    }

    // Called when the name picker closes (after adopting or renaming).
    function afterNaming() as Void {
        showingHelp = !StorageManager.hasSeenHelp();
        WatchUi.requestUpdate();
    }

    // Up/down or a left/right swipe flips between the pet page and the stats page.
    function toggleScreen() as Void {
        screen = (screen == SCREEN_PET) ? SCREEN_STATS : SCREEN_PET;
        WatchUi.requestUpdate();
    }

    function showPet() as Void {
        screen = SCREEN_PET;
        WatchUi.requestUpdate();
    }

    // The primary (START button / Care-button tap) action.
    function primaryAction() as Void {
        if (handlePrimary()) {
            return;
        }
        openCare();
    }

    function openCare() as Void {
        WatchUi.pushView(buildCareMenu(), new CareMenuDelegate(self), WatchUi.SLIDE_UP);
    }

    // Touch routing: only the Care button opens Care; tapping anywhere else on
    // the pet page flips to the Stats page (and a tap on Stats returns).
    function handleTap(x as Number, y as Number) as Void {
        if (choosingPet) {
            choosePet();
            return;
        }
        if (showingHelp) {
            dismissHelp();
            return;
        }
        if (animType != null) {
            return;
        }
        // Care is on the START button; a tap flips between Pet and Stats.
        toggleScreen();
    }

    // The primary (START/tap) action. Handles the contextual cases directly and
    // returns true; returns false when the caller should open the Care menu.
    function handlePrimary() as Boolean {
        if (showingHelp) {
            dismissHelp();
            return true;
        }
        if (!pet.alive) {
            pet.beginLegacy();
            afterCare();
            return true;
        }
        if (pet.stage == STAGE_EGG) {
            pet.hatch();
            afterCare();
            return true;
        }
        if (pet.isSleeping()) {
            pet.wake();
            afterCare();
            return true;
        }
        if (screen == SCREEN_STATS) {
            showPet();
            return true;
        }
        return false;
    }

    // Called by the Care menu to apply a chosen action.
    function performCare(action as Symbol) as Void {
        if (!pet.alive || pet.stage == STAGE_EGG) {
            return;
        }
        if (action == :feed) {
            pet.feed();
        } else if (action == :play) {
            pet.play();
        } else if (action == :clean) {
            pet.clean();
        } else if (action == :sleep) {
            pet.sleep();
        } else if (action == :medicine) {
            pet.medicine();
        } else if (action == :discipline) {
            pet.discipline();
        }
        afterCare();
        startAnim(action);
    }

    function animMaxFor(type as Symbol) as Number {
        if (type == :feed) { return 4; }   // bites
        if (type == :clean) { return 9; }
        if (type == :play) { return 8; }
        if (type == :sleep) { return 7; }
        if (type == :medicine) { return 6; }
        return 0;
    }

    // Plays a short visual flourish for a care action. The stat effect has
    // already been applied; this is pure juice.
    function startAnim(type as Symbol) as Void {
        var m = animMaxFor(type);
        if (m <= 0) {
            return;
        }
        animType = type;
        animStep = 0;
        animMax = m;
        if (animTimer == null) {
            animTimer = new Timer.Timer();
        }
        animTimer.start(method(:onAnimTick), ANIM_INTERVAL, true);
        WatchUi.requestUpdate();
    }

    function onAnimTick() as Void {
        animStep += 1;
        if (animStep > animMax) {
            stopAnim();
        } else {
            WatchUi.requestUpdate();
        }
    }

    function stopAnim() as Void {
        animType = null;
        if (animTimer != null) {
            animTimer.stop();
            animTimer = null;
        }
        WatchUi.requestUpdate();
    }

    function afterCare() as Void {
        StorageManager.savePet(pet);
        PetComplication.publish(pet);
        WatchUi.requestUpdate();
    }

    function dismissHelp() as Void {
        showingHelp = false;
        StorageManager.markHelpSeen();
        WatchUi.requestUpdate();
    }

    // Re-open the pet chooser so the player can pick a (new) pet. Adopting from
    // the chooser fully resets the pet's stats.
    function startChangePet() as Void {
        selectedPetType = pet.petType;
        choosingPet = true;
        showingHelp = false;
        WatchUi.requestUpdate();
    }

    // Wipe saved state and return to the chooser for a fresh start.
    function resetGame() as Void {
        StorageManager.resetAll();
        selectedPetType = PET_CAT;
        choosingPet = true;
        showingHelp = false;
        WatchUi.requestUpdate();
    }

    function drawBackground(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clock = System.getClockTime();
        var night = (clock.hour >= 20 || clock.hour < 6);
        var groundY = (h * 72) / 100;

        // Sky
        dc.setColor(night ? 0x0E1430 : 0x7BD2F6, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, groundY);

        if (night) {
            // Stars (fixed positions so they don't flicker around)
            dc.setColor(0xEDEFF7, Graphics.COLOR_TRANSPARENT);
            var sx = [12, 30, 52, 70, 90, 60, 38, 80];
            var sy = [18, 40, 14, 34, 22, 56, 60, 50];
            for (var i = 0; i < sx.size(); i++) {
                dc.fillRectangle((w * sx[i]) / 100, (groundY * sy[i]) / 100, 2, 2);
            }
            // Crescent moon
            dc.setColor(0xF2EFD0, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle((w * 78) / 100, (h * 20) / 100, 13);
            dc.setColor(0x0E1430, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle((w * 82) / 100, (h * 18) / 100, 11);
        } else {
            // Sun
            dc.setColor(0xFFE36E, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle((w * 80) / 100, (h * 19) / 100, 16);
            // Clouds
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            drawCloud(dc, (w * 24) / 100, (h * 18) / 100);
            drawCloud(dc, (w * 52) / 100, (h * 30) / 100);
        }

        // Ground
        dc.setColor(night ? 0x223046 : 0x5FBE53, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, groundY, w, h - groundY);
        dc.setColor(night ? 0x2C3C58 : 0x4FA646, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, groundY, w, 4);
    }

    function drawCloud(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillCircle(cx, cy, 9);
        dc.fillCircle(cx + 11, cy + 2, 11);
        dc.fillCircle(cx + 24, cy, 8);
        dc.fillRectangle(cx, cy, 24, 10);
    }

    function drawPetChooser(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var safeTop = safeTop(dc);
        var safeBottom = safeBottom(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, safeTop, Graphics.FONT_SMALL, "Choose Pet", Graphics.TEXT_JUSTIFY_CENTER);
        drawCenteredBitmap(dc, bitmapForPetType(selectedPetType, MOOD_HAPPY, STAGE_ADULT), w / 2, h / 2 - 8);
        dc.drawText(w / 2, safeBottom - 48, Graphics.FONT_SMALL, Pet.petTypeName(selectedPetType), Graphics.TEXT_JUSTIFY_CENTER);
        drawPill(dc, w / 2, safeBottom - 22, "Select");
    }

    function drawPetScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var top = safeTop(dc);
        var sprite = bitmapForState();
        var panelTop = (h * 60) / 100;

        // Anchor the pet so its feet rest just above the info panel.
        var bh = (sprite != null) ? sprite.getHeight() : 96;
        var cy = petAnchorY(h, bh);
        var bob;
        if (pet.isSleeping()) {
            bob = 0;
        } else if (pet.mood() == MOOD_HAPPY) {
            bob = (frame == 1) ? -4 : (frame == 3 ? -1 : 0);
        } else {
            bob = (frame == 1 || frame == 2) ? -2 : 0;   // gentle breathing
        }
        drawCenteredBitmap(dc, sprite, w / 2, cy + bob);

        if (pet.alive && pet.stage == STAGE_ADULT && pet.form != FORM_NEUTRAL) {
            drawFormAccessory(dc, w / 2, cy - (bh / 2) + 8 + bob);
        }
        if (pet.isSleeping()) {
            dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2 + 34, cy - 30, Graphics.FONT_TINY, "z", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(w / 2 + 44, cy - 44, Graphics.FONT_SMALL, "Z", Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Bottom info panel, or a contextual prompt for egg / death.
        if (!pet.alive) {
            drawPromptPanel(dc, w, h, panelTop, "Press START", "for a new egg");
        } else if (pet.stage == STAGE_EGG) {
            drawPromptPanel(dc, w, h, panelTop, "Press START", "to hatch!");
        } else {
            drawActivityPanel(dc, w, h, panelTop);
            if (pet.poopCount > 0) {
                drawPoops(dc, w, panelTop + 6);
            }
        }

        // Title last, on top of the pet's head, with a black outline.
        drawOutlinedTitle(dc, w / 2, top, pet.name + " - " + stageName() + pet.formSymbol());
    }

    // Feet rest just above the bottom info panel; clamp only so the head stays
    // on screen (the title is drawn over it with an outline for readability).
    function petAnchorY(h as Number, bh as Number) as Number {
        var panelTop = (h * 60) / 100;
        // The sprite has transparent space below the feet (the feet sit ~87% of
        // the way down), so sink it until the feet rest on the panel instead of
        // floating above it.
        var cy = panelTop + 2 - ((bh * 37) / 100);
        var minCy = (bh / 2) + 2;
        if (cy < minCy) {
            cy = minCy;
        }
        return cy;
    }

    // White text with a 1px black outline (8 directions), for legibility over
    // the pet and the sky.
    function drawOutlinedTitle(dc as Dc, cx as Number, y as Number, text as String) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 1, y - 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 1, y - 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx - 1, y + 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 1, y + 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx - 1, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 1, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, y - 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, y + 1, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Live activity readout (steps / heart rate / happiness) along the bottom.
    function drawActivityPanel(dc as Dc, w as Number, h as Number, panelTop as Number) as Void {
        var panelH = h - panelTop;
        dc.setColor(0x3E8E3A, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, panelTop, w, panelH);
        dc.setColor(0x5FBE53, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, panelTop, w, 3);

        var steps = pet.readSteps();
        var hr = pet.readHeartRate();
        var hrText = (hr != null && hr > 0) ? (hr.format("%d") + " bpm") : "--";

        var iconX = (w / 2) - 66;
        var textX = (w / 2) - 50;
        var rowGap = panelH / 4;
        var r1 = panelTop + rowGap;
        var r2 = panelTop + rowGap * 2;
        var r3 = panelTop + rowGap * 3;

        drawFeetIcon(dc, iconX, r1);
        drawHeartIcon(dc, iconX, r2);
        drawStarIcon(dc, iconX, r3);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, r1, Graphics.FONT_TINY, "STEPS: " + commafy(steps), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(textX, r2, Graphics.FONT_TINY, "HR: " + hrText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(textX, r3, Graphics.FONT_TINY, "HAPPY: " + pet.happiness.toNumber().format("%d") + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawPromptPanel(dc as Dc, w as Number, h as Number, panelTop as Number, line1 as String, line2 as String) as Void {
        dc.setColor(0x3E8E3A, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, panelTop, w, h - panelTop);
        dc.setColor(0x5FBE53, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, panelTop, w, 3);
        var midY = panelTop + (h - panelTop) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, midY - 11, Graphics.FONT_TINY, line1, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, midY + 11, Graphics.FONT_TINY, line2, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawFeetIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0x9FD8FF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 5, cy - 5, 4, 7, 2);
        dc.fillCircle(cx - 3, cy - 5, 2);
        dc.fillRoundedRectangle(cx + 1, cy - 1, 4, 7, 2);
        dc.fillCircle(cx + 3, cy - 1, 2);
    }

    function drawHeartIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 3, cy - 2, 3);
        dc.fillCircle(cx + 3, cy - 2, 3);
        dc.fillPolygon([[cx - 6, cy - 1], [cx + 6, cy - 1], [cx, cy + 6]]);
    }

    function drawStarIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0xFFD23F, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx, cy - 6], [cx + 2, cy - 2], [cx + 6, cy - 2], [cx + 3, cy + 1],
            [cx + 4, cy + 5], [cx, cy + 3], [cx - 4, cy + 5], [cx - 3, cy + 1],
            [cx - 6, cy - 2], [cx - 2, cy - 2]
        ]);
    }

    function commafy(n as Number) as String {
        var s = n.format("%d");
        var out = "";
        var count = 0;
        for (var i = s.length() - 1; i >= 0; i--) {
            out = s.substring(i, i + 1) + out;
            count += 1;
            if (count % 3 == 0 && i > 0) {
                out = "," + out;
            }
        }
        return out;
    }

    function drawHelp(dc as Dc) as Void {
        var w = dc.getWidth();
        var top = safeTop(dc);
        var bottom = safeBottom(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, top, Graphics.FONT_SMALL, "Controls", Graphics.TEXT_JUSTIFY_CENTER);

        drawHelpLine(dc, top + 44, "START: care");
        drawHelpLine(dc, top + 70, "TAP / UP / DOWN: stats");
        drawHelpLine(dc, top + 96, "MENU: settings");
        drawHelpLine(dc, top + 122, "BACK: exit");
        drawPill(dc, w / 2, bottom - 20, "Got it");
    }

    function drawHelpLine(dc as Dc, y as Number, text as String) as Void {
        var w = dc.getWidth();
        var boxW = 142;
        var x = (w - boxW) / 2;
        dc.setColor(0x2B2227, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, boxW, 20);
        dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y - 1, Graphics.FONT_TINY, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Small left-edge affordance showing which page up/down (or a swipe) leads to.
    function drawPageHint(dc as Dc, label as String) as Void {
        var h = dc.getHeight();
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(12, h / 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    const STAT_HUNGER = 0;
    const STAT_HAPPY = 1;
    const STAT_ENERGY = 2;
    const STAT_HEALTH = 3;
    const STAT_CLEAN = 4;

    // Dedicated stats page (reached by paging/swiping from the pet screen).
    function drawStatsScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var top = safeTop(dc);
        drawOutlinedTitle(dc, w / 2, top, pet.name + " - " + stageName() + pet.formSymbol());

        var iconSize = 9;
        var pad = 6;
        var valW = 28;
        var barW = minNum(w - 132, 116);
        var rowW = iconSize + pad + barW + 6 + valW;
        var x = (w - rowW) / 2;

        // Dark panel behind the bars so they stay readable over the day/night scene.
        var panelX = x - 12;
        var panelW = rowW + 24;
        if (panelX < 4) {
            panelX = 4;
            panelW = w - 8;
        }
        var panelTop = top + 40;
        dc.setColor(0x0E1B2E, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(panelX, panelTop, panelW, safeBottom(dc) + 2 - panelTop, 10);

        dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, top + 24, Graphics.FONT_XTINY, shortMessage(), Graphics.TEXT_JUSTIFY_CENTER);

        var regionTop = top + 44;
        var regionBottom = safeBottom(dc) - 16;
        var gap = (regionBottom - regionTop) / 5;
        var y = regionTop + (gap / 2) - 4;

        drawStatFull(dc, x, y, iconSize, pad, barW, STAT_HUNGER, pet.hunger, 0xFFDD55);
        drawStatFull(dc, x, y + gap, iconSize, pad, barW, STAT_HAPPY, pet.happiness, 0xDA3741);
        drawStatFull(dc, x, y + gap * 2, iconSize, pad, barW, STAT_ENERGY, pet.energy, 0x4CAAE8);
        drawStatFull(dc, x, y + gap * 3, iconSize, pad, barW, STAT_HEALTH, pet.health, 0x73E09B);
        drawStatFull(dc, x, y + gap * 4, iconSize, pad, barW, STAT_CLEAN, pet.cleanliness, 0xFFF0CC);

        // Footer: generation, inherited trait and age.
        var info = "Gen " + pet.generation;
        if (pet.trait != TRAIT_NONE) {
            info += " - " + Pet.traitName(pet.trait);
        }
        info += " - " + pet.ageDays() + "d";
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, safeBottom(dc) - 6, Graphics.FONT_XTINY, info, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawPageHint(dc, "Pet");
    }

    function drawStatFull(dc as Dc, x as Number, y as Number, iconSize as Number, pad as Number, barW as Number, stat as Number, value as Numeric, color as Number) as Void {
        drawStatIcon(dc, x, y, stat, color);
        var bx = x + iconSize + pad;
        drawMeter(dc, bx, y + 1, barW, value, color);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bx + barW + 6, y + 4, Graphics.FONT_XTINY, value.toNumber().format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Tiny per-stat glyphs so the bars are identifiable at a glance.
    function drawStatIcon(dc as Dc, ix as Number, iy as Number, stat as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (stat == STAT_HUNGER) {
            // Fork
            dc.fillRectangle(ix + 2, iy, 1, 4);
            dc.fillRectangle(ix + 4, iy, 1, 4);
            dc.fillRectangle(ix + 6, iy, 1, 4);
            dc.fillRectangle(ix + 2, iy + 3, 5, 1);
            dc.fillRectangle(ix + 4, iy + 3, 1, 6);
        } else if (stat == STAT_HAPPY) {
            // Heart
            dc.fillCircle(ix + 3, iy + 3, 2);
            dc.fillCircle(ix + 6, iy + 3, 2);
            dc.fillPolygon([[ix + 1, iy + 4], [ix + 8, iy + 4], [ix + 4, iy + 8]]);
        } else if (stat == STAT_ENERGY) {
            // Lightning bolt
            dc.fillPolygon([[ix + 5, iy], [ix + 1, iy + 5], [ix + 4, iy + 5], [ix + 3, iy + 9], [ix + 8, iy + 4], [ix + 5, iy + 4]]);
        } else if (stat == STAT_HEALTH) {
            // Plus / cross
            dc.fillRectangle(ix + 3, iy + 1, 3, 7);
            dc.fillRectangle(ix + 1, iy + 3, 7, 3);
        } else {
            // Cleanliness: water drop
            dc.fillPolygon([[ix + 4, iy], [ix + 1, iy + 5], [ix + 7, iy + 5]]);
            dc.fillCircle(ix + 4, iy + 6, 3);
        }
    }

    function drawMeter(dc as Dc, x as Number, y as Number, w as Number, value as Numeric, color as Number) as Void {
        var fill = (((w - 2) * value) / 100).toNumber();
        dc.setColor(0x2B2227, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, 7);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 1, y + 1, fill, 5);
    }

    // ---- Care action animations -------------------------------------------

    function drawActionAnim(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var top = safeTop(dc);

        var sprite;
        if ((animType == :feed || animType == :play) && pet.alive && pet.stage != STAGE_EGG && pet.stage != STAGE_BABY) {
            sprite = bitmapForPetType(pet.petType, MOOD_HAPPY, pet.stage);
        } else {
            sprite = bitmapForState();
        }
        var bh = (sprite != null) ? sprite.getHeight() : 96;
        var cy = petAnchorY(h, bh);
        drawCenteredBitmap(dc, sprite, w / 2, cy);

        drawOutlinedTitle(dc, w / 2, top, pet.name + " - " + stageName() + pet.formSymbol());

        if (animType == :feed) {
            drawFeedAnim(dc, w / 2, cy);
        } else if (animType == :clean) {
            drawCleanAnim(dc, w / 2, top);
        } else if (animType == :play) {
            drawPlayAnim(dc, w / 2, cy);
        } else if (animType == :sleep) {
            drawRestAnim(dc, w / 2, cy);
        } else if (animType == :medicine) {
            drawMedicineAnim(dc, w / 2, cy);
        }
    }

    // Each animal eats its own food, consumed a bite at a time. When it's gone,
    // a little sparkle remains.
    function drawFeedAnim(dc as Dc, cx as Number, petCy as Number) as Void {
        var remaining = (animMax - animStep).toFloat() / animMax;
        var by = petCy - 32;
        if (remaining <= 0) {
            drawSparkles(dc, cx, by + 16);
            return;
        }
        var kind = foodKind();
        if (kind == :fish) {
            drawFoodFish(dc, cx, by, remaining);
        } else if (kind == :bone) {
            drawFoodBone(dc, cx, by, remaining);
        } else if (kind == :meat) {
            drawFoodMeat(dc, cx, by, remaining);
        } else if (kind == :berries) {
            drawFoodBerries(dc, cx, by, remaining);
        } else {
            drawFoodBurger(dc, cx, by, remaining);
        }
    }

    function foodKind() as Symbol {
        switch (pet.petType) {
            case PET_CAT: return :fish;
            case PET_DOG: return :bone;
            case PET_DRAGON: return :meat;
            case PET_PENGUIN: return :fish;
            case PET_FOX: return :berries;
        }
        return :burger;
    }

    function drawFoodFish(dc as Dc, cx as Number, by as Number, remaining as Float) as Void {
        var visW = (46 * remaining).toNumber();
        if (visW < 8) { visW = 8; }
        var x = cx - 23;
        var midY = by + 8;
        dc.setColor(0x4CAAE8, Graphics.COLOR_TRANSPARENT);
        if (remaining > 0.5) {
            dc.fillPolygon([[x + visW, midY], [x + visW + 8, midY - 7], [x + visW + 8, midY + 7]]);
        }
        dc.fillRoundedRectangle(x, by, visW, 16, 8);
        dc.setColor(0x9FD8FF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, by + 9, visW, 5, 3);
        dc.setColor(0x1B1C32, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + 6, by + 6, 1);
    }

    function drawFoodBone(dc as Dc, cx as Number, by as Number, remaining as Float) as Void {
        var visW = (40 * remaining).toNumber();
        if (visW < 10) { visW = 10; }
        var x = cx - 20;
        var midY = by + 8;
        dc.setColor(0xFFF4D6, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, midY - 3, visW, 6, 3);
        dc.fillCircle(x, midY - 3, 3);
        dc.fillCircle(x, midY + 3, 3);
        dc.fillCircle(x + visW, midY - 3, 3);
        dc.fillCircle(x + visW, midY + 3, 3);
    }

    function drawFoodMeat(dc as Dc, cx as Number, by as Number, remaining as Float) as Void {
        var x = cx - 18;
        var midY = by + 8;
        var r = (4 + 8 * remaining).toNumber();
        dc.setColor(0xFFF4D6, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x + 18, midY - 2, 14, 5, 2);
        dc.fillCircle(x + 32, midY, 3);
        dc.setColor(0x8B5A2B, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + 12, midY, r);
    }

    function drawFoodBerries(dc as Dc, cx as Number, by as Number, remaining as Float) as Void {
        var shown = Math.ceil(remaining * 4).toNumber();
        var cols = [0xDA3741, 0x8958CB, 0xDA3741, 0x8958CB];
        var ox = [-12, 0, 12, 2];
        var oy = [2, -2, 3, 12];
        dc.setColor(0x5FBE53, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 1, by - 4, 2, 6);
        for (var i = 0; i < shown; i++) {
            dc.setColor(cols[i], Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx + ox[i], by + 6 + oy[i], 5);
        }
    }

    function drawFoodBurger(dc as Dc, cx as Number, by as Number, remaining as Float) as Void {
        var visW = (56 * remaining).toNumber();
        if (visW < 8) { visW = 8; }
        var x = cx - 28;
        dc.setColor(0xE8A85A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, by, visW, 15, 7);
        dc.setColor(0xFFF4D6, Graphics.COLOR_TRANSPARENT);
        for (var s = 0; s < 3; s++) {
            var sx = x + 8 + s * 14;
            if (sx < x + visW - 3) { dc.fillCircle(sx, by + 5, 1); }
        }
        dc.setColor(0x73E09B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, by + 13, visW, 6, 3);
        dc.setColor(0x8B5A2B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, by + 18, visW, 9, 3);
        dc.setColor(0xD98B3A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, by + 26, visW, 12, 6);
    }

    // A pill bobbing in front of the pet, with a sparkle as it takes effect.
    function drawMedicineAnim(dc as Dc, cx as Number, petCy as Number) as Void {
        var by = petCy - 30;
        var bob = (animStep % 2 == 0) ? 0 : -3;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 13, by + bob, 26, 11, 5);
        dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 13, by + bob, 13, 11, 5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 8, by + bob + 4, 3, 3);
        if (animStep >= animMax - 2) {
            drawSparkles(dc, cx, by - 6);
        }
    }

    // Poop piles on the ground until the pet is cleaned.
    function drawPoops(dc as Dc, w as Number, groundY as Number) as Void {
        var offs = [-80, 80, -56, 56];
        var n = pet.poopCount;
        if (n > 4) { n = 4; }
        for (var i = 0; i < n; i++) {
            drawPoop(dc, (w / 2) + offs[i], groundY);
        }
    }

    function drawPoop(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(0x6B4A2A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x - 9, y - 5, 18, 7, 3);
        dc.fillRoundedRectangle(x - 6, y - 10, 12, 7, 3);
        dc.fillRoundedRectangle(x - 3, y - 14, 6, 5, 2);
        dc.setColor(0x8A623C, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - 2, y - 9, 1);
    }

    // A small marker above an adult showing the form it grew into.
    function drawFormAccessory(dc as Dc, cx as Number, y as Number) as Void {
        if (pet.form == FORM_RADIANT) {
            dc.setColor(0xFFD23F, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[cx - 12, y + 8], [cx - 12, y], [cx - 6, y + 5], [cx, y - 5], [cx + 6, y + 5], [cx + 12, y], [cx + 12, y + 8]]);
            dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, y - 4, 2);
        } else {
            dc.setColor(0x8E97A3, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx - 8, y + 4, 6);
            dc.fillCircle(cx + 8, y + 4, 6);
            dc.fillCircle(cx, y, 8);
            dc.fillRectangle(cx - 12, y + 4, 24, 6);
            dc.setColor(0x4CAAE8, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx - 8, y + 12, 2, 5);
            dc.fillRectangle(cx, y + 13, 2, 5);
            dc.fillRectangle(cx + 8, y + 12, 2, 5);
        }
    }

    function drawSparkles(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0xFFF2A8, Graphics.COLOR_TRANSPARENT);
        drawSpark(dc, cx, cy);
        drawSpark(dc, cx - 16, cy - 8);
        drawSpark(dc, cx + 16, cy - 6);
    }

    function drawSpark(dc as Dc, x as Number, y as Number) as Void {
        dc.fillRectangle(x - 1, y - 4, 2, 8);
        dc.fillRectangle(x - 4, y - 1, 8, 2);
    }

    // Falling water streaks plus a few soap bubbles near the end.
    function drawCleanAnim(dc as Dc, cx as Number, top as Number) as Void {
        var h = dc.getHeight();
        var span = (h * 58) / 100;
        dc.setColor(0x9FD8FF, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 7; i++) {
            var dx = cx - 54 + i * 18;
            var dy = top + 18 + ((animStep * 17 + i * 21) % span);
            dc.fillRectangle(dx, dy, 2, 7);
            dc.fillCircle(dx + 1, dy + 9, 2);
        }
        if (animStep >= animMax - 3) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx - 24, top + 60, 4);
            dc.fillCircle(cx + 26, top + 78, 5);
            dc.fillCircle(cx + 6, top + 50, 3);
        }
    }

    // A ball bouncing across in front of the pet.
    function drawPlayAnim(dc as Dc, cx as Number, cy as Number) as Void {
        var bx = cx - 44 + (animStep * 88 / animMax);
        var bounce = animStep % 4;
        if (bounce == 3) { bounce = 1; }
        var by = cy + 30 - bounce * 12;
        dc.setColor(0xDA3741, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(bx, by, 7);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(bx - 2, by - 2, 2);
    }

    // "Z"s drifting up from the pet.
    function drawRestAnim(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0xCFE8FF, Graphics.COLOR_TRANSPARENT);
        var baseX = cx + 14;
        var baseY = cy - 16;
        dc.drawText(baseX, baseY - animStep * 3, Graphics.FONT_SMALL, "Z", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(baseX + 14, baseY - 12 - animStep * 4, Graphics.FONT_TINY, "Z", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(baseX + 24, baseY - 22 - animStep * 5, Graphics.FONT_XTINY, "Z", Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawPill(dc as Dc, cx as Number, y as Number, label as String) as Void {
        var w = minNum(dc.getWidth() - 118, 104);
        dc.setColor(0x2B2227, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - (w / 2), y, w, 24);
        dc.setColor(0xFFDD55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y - 4, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawCenteredBitmap(dc as Dc, bmp, cx as Number, cy as Number) as Void {
        if (bmp == null) {
            drawFallbackPet(dc, cx, cy, 3);
            return;
        }
        var bw = bmp.getWidth();
        var bh = bmp.getHeight();
        dc.drawBitmap(cx - (bw / 2), cy - (bh / 2), bmp);
    }

    function drawFallbackPet(dc as Dc, cx as Number, cy as Number, scale as Number) as Void {
        var s = scale;
        dc.setColor(0x2B2227, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 12 * s, cy - 11 * s, 24 * s, 24 * s);
        dc.setColor(0xEE842B, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 10 * s, cy - 10 * s, 20 * s, 20 * s);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 6 * s, cy - 2 * s, 3 * s, 4 * s);
        dc.fillRectangle(cx + 3 * s, cy - 2 * s, 3 * s, 4 * s);
    }

    // Single-slot bitmap cache. Only one sprite is ever shown per redraw, and it
    // stays the same across frames, so this turns ~1 PNG decode per second into
    // one decode per actual sprite change.
    function cachedDrawable(id) {
        if (spriteCache == null || spriteCacheId != id) {
            spriteCache = WatchUi.loadResource(id);
            spriteCacheId = id;
        }
        return spriteCache;
    }

    function bitmapForState() {
        if (!pet.alive) {
            return cachedDrawable(Rez.Drawables.Ghost);
        }
        if (pet.stage == STAGE_EGG) {
            return cachedDrawable(Rez.Drawables.Egg);
        }
        if (pet.stage == STAGE_BABY) {
            return cachedDrawable(Rez.Drawables.Baby);
        }
        return bitmapForPetType(pet.petType, pet.mood(), pet.stage);
    }

    function bitmapForPetType(type as Number, mood as Number, stage as Number) {
        if (type == PET_CAT) {
            if (mood == MOOD_HAPPY) { return cachedDrawable(Rez.Drawables.CatHappy); }
            if (mood == MOOD_SAD) { return cachedDrawable(Rez.Drawables.CatSad); }
            if (mood == MOOD_SLEEP) { return cachedDrawable(Rez.Drawables.CatSleep); }
            if (mood == MOOD_SICK) { return cachedDrawable(Rez.Drawables.CatSick); }
            return cachedDrawable(Rez.Drawables.CatIdle);
        }
        if (type == PET_DOG) {
            if (mood == MOOD_HAPPY) { return cachedDrawable(Rez.Drawables.DogHappy); }
            if (mood == MOOD_SAD) { return cachedDrawable(Rez.Drawables.DogSad); }
            if (mood == MOOD_SLEEP) { return cachedDrawable(Rez.Drawables.DogSleep); }
            if (mood == MOOD_SICK) { return cachedDrawable(Rez.Drawables.DogSick); }
            return cachedDrawable(Rez.Drawables.DogIdle);
        }
        if (type == PET_DRAGON) {
            if (mood == MOOD_HAPPY) { return cachedDrawable(Rez.Drawables.DragonHappy); }
            if (mood == MOOD_SAD) { return cachedDrawable(Rez.Drawables.DragonSad); }
            if (mood == MOOD_SLEEP) { return cachedDrawable(Rez.Drawables.DragonSleep); }
            if (mood == MOOD_SICK) { return cachedDrawable(Rez.Drawables.DragonSick); }
            return cachedDrawable(Rez.Drawables.DragonIdle);
        }
        if (type == PET_PENGUIN) {
            if (mood == MOOD_HAPPY) { return cachedDrawable(Rez.Drawables.PenguinHappy); }
            if (mood == MOOD_SAD) { return cachedDrawable(Rez.Drawables.PenguinSad); }
            if (mood == MOOD_SLEEP) { return cachedDrawable(Rez.Drawables.PenguinSleep); }
            if (mood == MOOD_SICK) { return cachedDrawable(Rez.Drawables.PenguinSick); }
            return cachedDrawable(Rez.Drawables.PenguinIdle);
        }
        if (type == PET_FOX) {
            if (mood == MOOD_HAPPY) { return cachedDrawable(Rez.Drawables.FoxHappy); }
            if (mood == MOOD_SAD) { return cachedDrawable(Rez.Drawables.FoxSad); }
            if (mood == MOOD_SLEEP) { return cachedDrawable(Rez.Drawables.FoxSleep); }
            if (mood == MOOD_SICK) { return cachedDrawable(Rez.Drawables.FoxSick); }
            return cachedDrawable(Rez.Drawables.FoxIdle);
        }
        return cachedDrawable(Rez.Drawables.CatIdle);
    }

    function stageName() as String {
        switch (pet.stage) {
            case STAGE_EGG: return "Egg";
            case STAGE_BABY: return "Baby";
            case STAGE_TEEN: return "Teen";
            case STAGE_ADULT: return "Adult";
        }
        return "Pet";
    }

    function isSmall(dc as Dc) as Boolean {
        return minNum(dc.getWidth(), dc.getHeight()) < 218;
    }

    function safeTop(dc as Dc) as Number {
        return isSmall(dc) ? 12 : 24;
    }

    function safeBottom(dc as Dc) as Number {
        return dc.getHeight() - (isSmall(dc) ? 18 : 30);
    }

    function shortMessage() as String {
        if (!pet.alive) { return "Select to revive"; }
        var need = pet.primaryNeed();
        if (need == "Hungry") { return "Hungry"; }
        if (need == "Needs play") { return "Wants play"; }
        if (need == "Sleepy") { return "Sleepy"; }
        if (need == "Messy" && pet.isMessy()) { return "Messy"; }
        if (need == "Unwell") { return "Unwell"; }
        return pet.lastMessage;
    }

    function minNum(a as Number, b as Number) as Number {
        return (a < b) ? a : b;
    }
}

class TamawatchiInputDelegate extends WatchUi.BehaviorDelegate {
    var mainView as TamawatchiView;
    var pet as Pet;

    function initialize(viewRef as TamawatchiView, model as Pet) {
        BehaviorDelegate.initialize();
        mainView = viewRef;
        pet = model;
    }

    function view() as TamawatchiView {
        return mainView;
    }

    function onSelect() as Boolean {
        return activate();
    }

    function activate() as Boolean {
        var v = view();
        if (v.choosingPet) {
            v.choosePet();
        } else {
            v.primaryAction();
        }
        return true;
    }

    function onTap(evt as ClickEvent) as Boolean {
        var c = evt.getCoordinates();
        if (c != null) {
            view().handleTap(c[0], c[1]);
        }
        return true;
    }

    function onNextPage() as Boolean {
        return page(true);
    }

    function onPreviousPage() as Boolean {
        return page(false);
    }

    function onNextMode() as Boolean {
        return page(true);
    }

    function onPreviousMode() as Boolean {
        return page(false);
    }

    // Left/right swipe on touch devices also flips between the pages.
    function onSwipe(evt as SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_LEFT || dir == WatchUi.SWIPE_RIGHT) {
            return page(true);
        }
        return false;
    }

    function page(forward as Boolean) as Boolean {
        var v = view();
        if (v.choosingPet) {
            if (forward) { v.nextPet(); } else { v.previousPet(); }
        } else if (v.showingHelp) {
            v.dismissHelp();
        } else {
            v.toggleScreen();
        }
        return true;
    }

    function onMenu() as Boolean {
        if (mainView.choosingPet) {
            return true;
        }
        WatchUi.pushView(buildSettingsMenu(), new SettingsMenuDelegate(mainView), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() as Boolean {
        StorageManager.savePet(pet);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
