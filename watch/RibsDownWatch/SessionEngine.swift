import Foundation
import Combine
import WatchKit

/// Paces a session: counts holds down, counts reps up at tempo, runs rests,
/// and taps the wrist at 3-2-1 and at every change. Keeps running with the
/// wrist down through an extended runtime session (Background Modes:
/// Physical Therapy must be enabled on the target).
final class SessionEngine: NSObject, ObservableObject {
    @Published var steps: [Step] = []
    @Published var index: Int = 0
    @Published var stepElapsed: Double = 0
    @Published var totalElapsed: Double = 0
    @Published var reps: Int = 0
    @Published var paused: Bool = false
    @Published var finished: Bool = false
    @Published var log: [String] = []
    private(set) var title: String = ""

    private var timer: Timer?
    private var startedAt = Date()
    private var stepStart = Date()
    private var pausedAt: Date?
    private var lastBeep = -1
    private var lastTick = -1
    private var manualReps: Int?
    private var runtime: WKExtendedRuntimeSession?

    var step: Step {
        steps.isEmpty ? Step(kind: .finish) : steps[min(index, steps.count - 1)]
    }

    var nextExercise: Exercise? {
        guard !steps.isEmpty else { return nil }
        for j in (index + 1)..<steps.count where steps[j].kind == .exercise {
            return steps[j].exercise
        }
        return nil
    }

    func start(kinds: [SessionKind]) {
        stop()
        title = Program.title(for: kinds)
        steps = Program.steps(for: kinds)
        index = 0
        reps = 0
        log = []
        finished = false
        paused = false
        startedAt = Date()
        stepStart = startedAt
        pausedAt = nil
        manualReps = nil
        lastBeep = -1
        lastTick = -1
        beginRuntime()
        haptic(.start)
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        runtime?.invalidate()
        runtime = nil
    }

    private var now: Date { pausedAt ?? Date() }

    private func haptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    private func tick() {
        totalElapsed = now.timeIntervalSince(startedAt)
        stepElapsed = now.timeIntervalSince(stepStart)
        let st = step
        switch st.kind {
        case .exercise:
            guard let ex = st.exercise else { return }
            if ex.mode == .time {
                let remaining = Double(ex.target) - stepElapsed
                countdownHaptics(remaining)
                if remaining <= 0 && !paused {
                    haptic(.success)
                    advance()
                }
            } else {
                let auto = min(ex.target + 5, Int(stepElapsed / ex.tempo))
                reps = manualReps ?? auto
                if manualReps == nil && auto != lastTick && !paused {
                    if lastTick >= 0 && auto <= ex.target { haptic(.click) }
                    lastTick = auto
                }
            }
        case .rest, .switchSides:
            let remaining = st.seconds - stepElapsed
            countdownHaptics(remaining)
            if remaining <= 0 && !paused {
                haptic(.notification)
                advance()
            }
        case .finish:
            break
        }
    }

    private func countdownHaptics(_ remaining: Double) {
        let sec = Int(ceil(remaining))
        if sec <= 3 && sec > 0 && lastBeep != sec && !paused {
            lastBeep = sec
            haptic(.click)
        }
    }

    /// Records the current exercise step (unless skipping) and moves on.
    func advance(by n: Int = 1, logging: Bool = true) {
        let st = step
        if logging, st.kind == .exercise, let ex = st.exercise {
            let side = st.side.map { " (\($0))" } ?? ""
            let result = ex.mode == .time ? "\(ex.target)s" : "\(reps) reps"
            log.append("\(ex.name)\(side): \(result)")
        }
        index = min(steps.count - 1, index + n)
        stepStart = now
        manualReps = nil
        lastBeep = -1
        lastTick = -1
        reps = 0
        if step.kind == .finish { finish() }
    }

    func done() { advance() }

    func skip() {
        let st = step
        if st.kind == .exercise, st.side == "Left", index + 1 < steps.count, steps[index + 1].kind == .switchSides {
            advance(by: 3, logging: false)
        } else {
            advance(logging: false)
        }
    }

    func adjust(_ delta: Int) {
        let value = max(0, (manualReps ?? reps) + delta)
        manualReps = value
        reps = value
    }

    func addRest(_ seconds: Double) {
        guard index < steps.count else { return }
        steps[index].seconds += seconds
        lastBeep = -1
    }

    func togglePause() {
        if let p = pausedAt {
            let dt = Date().timeIntervalSince(p)
            startedAt = startedAt.addingTimeInterval(dt)
            stepStart = stepStart.addingTimeInterval(dt)
            pausedAt = nil
            paused = false
        } else {
            pausedAt = Date()
            paused = true
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
