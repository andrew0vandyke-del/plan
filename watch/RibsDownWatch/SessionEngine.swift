import Foundation
import Combine
import WatchKit

/// Runs a session the same way the phone app does: you log each set with
/// the steppers, holds are countdowns you start yourself, rest runs on its
/// own with the next card already showing, and the core circuit auto-runs.
/// Haptic taps at 3-2-1 and at every change. An extended runtime session
/// keeps it alive with the wrist down (Background Modes: Physical Therapy).
final class SessionEngine: NSObject, ObservableObject {
    enum Phase { case idle, hold, switchSides }

    @Published var units: [Unit] = []
    @Published var index: Int = 0
    @Published var phase: Phase = .idle
    @Published var side: String = "Left"
    @Published var resting: Bool = false
    @Published var restRemaining: Double = 0
    @Published var restTotal: Double = 1
    @Published var restLabel: String = "Rest"
    @Published var remaining: Double = 0
    @Published var progress: Double = 0
    @Published var totalElapsed: Double = 0
    @Published var reps: Int = 0
    @Published var repsLeft: Int = 0
    @Published var repsRight: Int = 0
    @Published var paused: Bool = false
    @Published var finished: Bool = false
    @Published var log: [String] = []
    @Published var coreDone: Int = 0
    private(set) var coreTotal: Int = 0
    private(set) var title: String = ""

    private var timer: Timer?
    private var startedAt = Date()
    private var phaseStart = Date()
    private var phaseDuration: Double = 0
    private var restUntil = Date()
    private var pausedAt: Date?
    private var lastBeep = -1
    private var midCued = false
    private var runtime: WKExtendedRuntimeSession?

    var unit: Unit { units.isEmpty ? Unit(kind: .finish) : units[min(index, units.count - 1)] }

    var nextLabel: String {
        guard index + 1 < units.count else { return "" }
        let n = units[index + 1]
        switch n.kind {
        case .set: return "\(n.exercise?.name ?? "") · set \(n.set)"
        case .interval: return n.exercise?.name ?? ""
        case .lead: return "Core finisher"
        case .finish: return "Finish"
        }
    }

    // MARK: lifecycle

    func start(kinds: [SessionKind]) {
        stop()
        title = Program.title(for: kinds)
        units = Program.units(for: kinds)
        coreTotal = units.filter { $0.kind == .interval }.count
        log = []
        coreDone = 0
        finished = false
        paused = false
        resting = false
        pausedAt = nil
        startedAt = Date()
        beginRuntime()
        haptic(.start)
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.tick() }
        goto(0)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        runtime?.invalidate()
        runtime = nil
    }

    private var now: Date { pausedAt ?? Date() }
    private func haptic(_ type: WKHapticType) { WKInterfaceDevice.current().play(type) }

    private func goto(_ i: Int) {
        index = min(i, units.count - 1)
        phase = .idle
        side = "Left"
        let t = unit.exercise?.target ?? 0
        reps = t; repsLeft = t; repsRight = t
        if unit.kind == .finish { resting = false; finish(); return }
        if !resting && (unit.kind == .lead || unit.kind == .interval) { startTimed() }
    }

    // MARK: user actions

    func startHold() {
        guard unit.kind == .set, unit.exercise?.mode == .time, phase == .idle, !resting else { return }
        haptic(.start)
        startTimed(side: "Left")
    }

    func logSet() {
        guard unit.kind == .set, let ex = unit.exercise, ex.mode == .reps, !resting else { return }
        if ex.perSide { log.append("\(ex.name): L \(repsLeft) · R \(repsRight)") }
        else { log.append("\(ex.name): \(reps) reps") }
        haptic(.click)
        complete()
    }

    func adjust(_ which: String, by delta: Int) {
        switch which {
        case "L": repsLeft = max(0, repsLeft + delta)
        case "R": repsRight = max(0, repsRight + delta)
        default: reps = max(0, reps + delta)
        }
    }

    func doneEarly() { if phase == .hold { finishTimed() } }
    func extendHold(_ seconds: Double) { if phase == .hold { phaseDuration += seconds; lastBeep = -1 } }
    func skip() { phase = .idle; complete(skipRest: true) }
    func addRest(_ seconds: Double) { guard resting else { return }; restUntil = restUntil.addingTimeInterval(seconds); restTotal += seconds; lastBeep = -1 }

    func skipRest() {
        guard resting else { return }
        resting = false
        if unit.kind == .lead || unit.kind == .interval { startTimed() }
    }

    func togglePause() {
        if let p = pausedAt {
            let dt = Date().timeIntervalSince(p)
            startedAt = startedAt.addingTimeInterval(dt)
            phaseStart = phaseStart.addingTimeInterval(dt)
            restUntil = restUntil.addingTimeInterval(dt)
            pausedAt = nil
            paused = false
        } else {
            pausedAt = Date()
            paused = true
        }
    }

    func endNow() {
        let j = units.firstIndex { $0.kind == .finish } ?? (units.count - 1)
        resting = false
        phase = .idle
        goto(j)
    }

    // MARK: internals

    private func startTimed(side: String = "Left") {
        phase = .hold
        self.side = side
        phaseStart = now
        phaseDuration = unit.kind == .set ? Double(unit.exercise?.target ?? 30) : unit.seconds
        lastBeep = -1
        midCued = false
    }

    private func complete(skipRest: Bool = false) {
        let u = unit
        let hasNext = index + 1 < units.count && units[index + 1].kind != .finish
        if !skipRest && u.restAfter > 0 && hasNext {
            resting = true
            restTotal = u.restAfter
            restRemaining = u.restAfter
            restUntil = now.addingTimeInterval(u.restAfter)
            restLabel = u.restLabel
            lastBeep = -1
        }
        goto(index + 1)
    }

    private func finishTimed() {
        let u = unit
        let ran = Int(min(phaseDuration, now.timeIntervalSince(phaseStart)).rounded())
        switch u.kind {
        case .set:
            if let ex = u.exercise {
                log.append("\(ex.name)\(ex.perSide ? " (\(side))" : ""): \(ran)s")
                if ex.perSide && side == "Left" {
                    phase = .switchSides
                    phaseStart = now
                    phaseDuration = 5
                    lastBeep = -1
                    haptic(.notification)
                    return
                }
            }
            haptic(.success)
            complete()
        case .interval:
            coreDone += 1
            haptic(.success)
            complete()
        case .lead:
            haptic(.notification)
            complete()
        case .finish:
            break
        }
    }

    private func tick() {
        totalElapsed = now.timeIntervalSince(startedAt)
        if resting {
            let rem = restUntil.timeIntervalSince(now)
            restRemaining = max(0, rem)
            countdown(rem)
            if rem <= 0 && !paused {
                resting = false
                haptic(.notification)
                if unit.kind == .lead || unit.kind == .interval { startTimed() }
            }
        }
        if phase == .hold || phase == .switchSides {
            let t = now.timeIntervalSince(phaseStart)
            let rem = phaseDuration - t
            remaining = max(0, rem)
            progress = phaseDuration > 0 ? min(1, t / phaseDuration) : 1
            if unit.kind == .interval, unit.exercise?.perSide == true, !midCued, t >= phaseDuration / 2, !paused {
                midCued = true
                haptic(.directionUp)
            }
            countdown(rem)
            if rem <= 0 && !paused {
                if phase == .switchSides { startTimed(side: "Right") } else { finishTimed() }
            }
        }
    }

    private func countdown(_ remaining: Double) {
        let sec = Int(ceil(remaining))
        if sec <= 3 && sec > 0 && lastBeep != sec && !paused {
            lastBeep = sec
            haptic(.click)
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        finished = true
        runtime?.invalidate()
        runtime = nil
        haptic(.success)
    }
}

extension SessionEngine: WKExtendedRuntimeSessionDelegate {
    private func beginRuntime() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        runtime = session
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        runtime = nil
    }
}
