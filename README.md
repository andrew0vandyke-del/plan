# Ribs Down

A phone-first home workout app built from the **Home Workout Plan** (Nov 1, 2026): the daily 10-minute Back & Pelvis Block for anterior pelvic tilt, Day A (push + legs), Day B (pull + hinge), the Sunday walk, plus running days, a pace clock, exercise swaps and automatic progression.

Everything lives in one page (`app.html`). No build tools, no accounts, no external services.

## What it does

- **Today**: the session for today (Block, then Day A or B in the plan's alternating order, runs on your chosen days, walk on Sunday), one tap to start, quick actions for a low-energy "Block only" day, logging a run done elsewhere, or a gym day.
- **Session player**: a preview of the whole session first (sections, exercises, targets, time, equipment), then one exercise card at a time with a set table that shows the target, last time's numbers and what you log. Big −/+ steppers prefilled from your last session, left and right on one row, and a Log set button that starts the rest. Holds get a countdown ring you start yourself. Rest counts down in a bar at the bottom while the next exercise is already on screen. Supersets run as rounds with the partner exercise named. A menu covers swap, skip, pause and end-early.
- **Core finisher**: a 5 or 10 minute timed circuit added to every day, rotated daily from a pool of pelvis-safe ab moves (no sit-ups or leg raises that lift the low back), with a get-ready countdown, auto-run intervals, a switch cue for one-sided moves, and its own progression.
- **Visuals**: an animated figure for every exercise showing the start and end position.
- **Progression**: rate each session 1-10. Hit the top of the rep range and rate it 7 or lower and the app moves you up the plan's ladder (harder variation, more backpack weight, slower lowering). Finishing well under the plan's target time counts as easier; well over counts as harder. Runs grow from 1 mile toward 4 for the long run based on your ratings. Core intervals lengthen from 40s toward 60s. New personal bests are flagged as you log them.
- **Switch it up**: every slot has alternatives that train the same goal (horizontal push, hinge, hamstring curl, and so on). Mix up a day with one tap, or let the app nudge you every 4 weeks.
- **Motivation**: streaks, XP levels, 21 badges, a daily line from the plan, confetti.
- **Progress**: 12-week heatmap, difficulty trend with the 6-8 target band, minutes per week, per-exercise bests, run pace and miles, bodyweight, full history.
- **Reminders**: a daily reminder while the page is open (with browser notifications where allowed), plus Google Calendar / `.ics` links for a repeating event with an alert. Posture-break nudges every 30-60 minutes, as the plan asks.
- **Recovery**: protein target from your bodyweight, sleep and walking notes, form rules for anterior pelvic tilt, daily habit check-offs.

## iPhone and Apple Watch

- **iPhone**: open the hosted link in Safari, then Share → **Add to Home Screen**. Installed, it runs full screen under the status bar, works offline, keeps the screen awake during a workout, and can send reminders once you tap Allow under More → Reminders. Icons are full-bleed so iOS rounds them properly.
- **Apple Watch**: a web page cannot run on the Watch. Two things work today: calendar reminders buzz the wrist, and runs recorded in the Watch Workout app can be logged in the app afterwards. For pacing on the wrist, the `watch/` folder holds a native SwiftUI companion app (Block and Day A/B pace clock with haptics, run stopwatch) that needs a one-time build in Xcode. See `watch/README.md`.

## Run it

- **Hosted**: open the published Claude artifact (data syncs through your Claude account across devices).
- **Self-hosted**: serve this folder (GitHub Pages works: Settings → Pages → deploy from `main`, root). Open `index.html`, then "Add to Home Screen" for a full-screen, offline-capable app. Data stays in that browser; use Export/Import under More to move it.

## Files

| File | Purpose |
|---|---|
| `app.html` | The whole app (styles, markup, script). This is what gets published as the artifact. |
| `head.html`, `tail.html`, `build.sh` | Wrap `app.html` into a standalone `index.html` with the PWA manifest. Run `./build.sh` after editing `app.html`. |
| `index.html` | Built output for self-hosting. |
| `manifest.webmanifest`, `sw.js`, `icon*.{svg,png}` | Installable-app metadata, offline cache, icons. |

## Editing the program

Exercises, slots, goals, badges and the plan's text live at the top of the script in `app.html` (`EX`, `SLOTS`, `GOALS`, `BADGES`, `QUOTES`). Each exercise has a `how`, a `cue`, a rep or hold range, a tempo, and optional `easier`/`harder` links that form its progression ladder.
