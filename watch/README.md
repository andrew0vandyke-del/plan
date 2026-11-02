# Ribs Down for Apple Watch

A small native watchOS companion that paces the Back & Pelvis Block and the Day A / Day B strength sessions on your wrist: a countdown ring for holds, auto-counted reps at each exercise's tempo, rests and side switches, with haptic taps at 3-2-1 and at every change. It keeps running with your wrist down. There is also a run stopwatch with mile splits.

It does not sync with the phone app. Rate and log each session on the phone afterwards; that is where progression lives. The watch uses the plan's base exercises and starting targets, which you can edit in `Program.swift` once you have moved up.

A web page cannot run on Apple Watch, so this has to be built once in Xcode on a Mac. The source here was written without access to Xcode, so expect to fix a warning or two on the first build.

## Build it (about 10 minutes)

1. On a Mac with Xcode 15 or newer, choose **File → New → Project → watchOS → App**. Name it `Ribs Down`, interface SwiftUI, language Swift. Untick "Include Tests".
2. In the new target's folder, delete the generated `Ribs_DownApp.swift` and `ContentView.swift`.
3. Drag the six `.swift` files from `watch/RibsDownWatch/` into that target (tick "Copy items if needed" and the Watch App target).
4. Select the Watch App target → **Signing & Capabilities** → **+ Capability** → **Background Modes**, then under *Extended runtime session* tick **Physical therapy**. This is what lets the timer and haptics continue when your wrist drops. (Equivalent Info.plist key: `WKBackgroundModes` containing `physical-therapy`.)
5. Set the deployment target to watchOS 9 or newer.
6. Pair your Watch with the Mac through your iPhone (Xcode → Window → Devices and Simulators), pick the Watch as the run destination, and press Run. A free Apple ID works for installing on your own device; the install expires after 7 days unless you have a paid developer account.

## Files

| File | What it does |
|---|---|
| `RibsDownWatchApp.swift` | App entry point. |
| `Program.swift` | The plan's exercises, sets, targets and tempos, plus the step builder (same sequencing as the phone app). |
| `SessionEngine.swift` | Timer, rep pacing, haptics, pause, and the extended runtime session. |
| `ContentView.swift` | Session picker. |
| `PlayerView.swift` | The on-wrist pace clock: ring, exercise, cue, Done / Skip / Pause. |
| `RunView.swift` | Stopwatch with mile splits. |

## Two things that already work without this app

- **Reminders on the wrist**: the phone app's calendar reminder (More → Reminders → Apple / Outlook) creates a repeating event with an alert, and the Watch buzzes for calendar alerts.
- **Runs**: start a run in the Watch's Workout app so it records to Apple Health, then log miles, time and rating in the phone app under "Log something else".
