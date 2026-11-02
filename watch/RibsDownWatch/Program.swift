import Foundation

// The plan's base exercises and targets. Progression lives in the phone app;
// edit the targets here if you have moved up and want the watch to match.

enum ExerciseMode { case time, reps }

struct Exercise {
    let name: String
    let cue: String
    let mode: ExerciseMode
    let perSide: Bool
    let target: Int        // seconds for .time, reps for .reps
    let tempo: Double      // seconds per rep, paces the automatic rep count
}

struct Slot {
    let label: String
    let sets: Int
    let pair: String?      // superset group within a day; nil for straight sets
    let exercise: Exercise
}

enum StepKind { case exercise, rest, switchSides, finish }

struct Step: Identifiable {
    let id = UUID()
    let kind: StepKind
    var exercise: Exercise? = nil
    var label: String = ""
    var set: Int = 0
    var sets: Int = 0
    var side: String? = nil
    var seconds: Double = 0
}

enum SessionKind {
    case block, dayA, dayB

    var title: String {
        switch self {
        case .block: return "Block"
        case .dayA: return "Day A"
        case .dayB: return "Day B"
        }
    }
}

enum Program {
    static let blockRest: Double = 15
    static let supersetRest: Double = 60
    static let finisherRest: Double = 45
    static let switchSeconds: Double = 6

    static let block: [Slot] = [
        Slot(label: "1", sets: 2, pair: nil, exercise: Exercise(name: "Half-kneeling hip flexor stretch", cue: "Tuck, squeeze the back glute, then lean", mode: .time, perSide: true, target: 45, tempo: 1)),
        Slot(label: "2", sets: 2, pair: nil, exercise: Exercise(name: "Dead bug", cue: "Low back glued to the floor, long exhale", mode: .reps, perSide: true, target: 8, tempo: 4)),
        Slot(label: "3", sets: 2, pair: nil, exercise: Exercise(name: "Bird dog", cue: "Tabletop back, 5-second hold", mode: .reps, perSide: true, target: 6, tempo: 6)),
        Slot(label: "4", sets: 2, pair: nil, exercise: Exercise(name: "Side plank", cue: "Straight line, hips slightly forward", mode: .time, perSide: true, target: 30, tempo: 1)),
        Slot(label: "5", sets: 2, pair: nil, exercise: Exercise(name: "Glute bridge", cue: "Tuck, drive heels, 2-second squeeze", mode: .reps, perSide: false, target: 12, tempo: 4)),
    ]

    static let dayA: [Slot] = [
        Slot(label: "A1", sets: 3, pair: "A", exercise: Exercise(name: "Push-up", cue: "Glutes squeezed, one straight line", mode: .reps, perSide: false, target: 10, tempo: 3)),
        Slot(label: "A2", sets: 3, pair: "A", exercise: Exercise(name: "Bulgarian split squat", cue: "Tuck the pelvis, squeeze the rear glute", mode: .reps, perSide: true, target: 8, tempo: 3)),
        Slot(label: "B1", sets: 3, pair: "B", exercise: Exercise(name: "Pike push-up", cue: "Hips high, head between the hands", mode: .reps, perSide: false, target: 6, tempo: 3)),
        Slot(label: "B2", sets: 3, pair: "B", exercise: Exercise(name: "Reverse crunch", cue: "Curl with the abs, lower slowly", mode: .reps, perSide: false, target: 10, tempo: 4)),
    ]

    static let dayB: [Slot] = [
        Slot(label: "A1", sets: 3, pair: "A", exercise: Exercise(name: "Inverted row", cue: "Body straight, squeeze the shoulder blades", mode: .reps, perSide: false, target: 8, tempo: 3)),
        Slot(label: "A2", sets: 3, pair: "A", exercise: Exercise(name: "Single-leg RDL", cue: "Torso and back leg move as one", mode: .reps, perSide: true, target: 8, tempo: 4)),
        Slot(label: "B1", sets: 3, pair: "B", exercise: Exercise(name: "Hip thrust", cue: "Chin tucked, tilt back and squeeze", mode: .reps, perSide: false, target: 10, tempo: 4)),
        Slot(label: "B2", sets: 3, pair: "B", exercise: Exercise(name: "Towel hamstring curl", cue: "Hips up, slide in and out", mode: .reps, perSide: false, target: 8, tempo: 4)),
        Slot(label: "C", sets: 2, pair: nil, exercise: Exercise(name: "Reverse hyper", cue: "To the line, no higher", mode: .reps, perSide: false, target: 12, tempo: 3)),
    ]

    static func title(for kinds: [SessionKind]) -> String {
        kinds.map { $0.title }.joined(separator: " + ")
    }

    /// Builds the ordered steps the same way the phone app does:
    /// Block exercises in order with short breathers, then supersets in rounds with a rest after each pair.
    static func steps(for kinds: [SessionKind]) -> [Step] {
        var steps: [Step] = []

        func push(_ slot: Slot, set: Int) {
            let ex = slot.exercise
            if ex.perSide {
                steps.append(Step(kind: .exercise, exercise: ex, label: slot.label, set: set, sets: slot.sets, side: "Left"))
                steps.append(Step(kind: .switchSides, label: "Switch sides", seconds: switchSeconds))
                steps.append(Step(kind: .exercise, exercise: ex, label: slot.label, set: set, sets: slot.sets, side: "Right"))
            } else {
                steps.append(Step(kind: .exercise, exercise: ex, label: slot.label, set: set, sets: slot.sets))
            }
        }

        for kind in kinds {
            switch kind {
            case .block:
                for (i, slot) in block.enumerated() {
                    for set in 1...slot.sets {
                        push(slot, set: set)
                        let last = set == slot.sets && i == block.count - 1
                        if !last { steps.append(Step(kind: .rest, label: "Breathe", seconds: blockRest)) }
                    }
                }
            case .dayA, .dayB:
                let slots = kind == .dayA ? dayA : dayB
                var pairs: [String] = []
                for s in slots {
                    if let p = s.pair, !pairs.contains(p) { pairs.append(p) }
                }
                for p in pairs {
                    let group = slots.filter { $0.pair == p }
                    let rounds = group.map { $0.sets }.max() ?? 0
                    if rounds == 0 { continue }
                    for round in 1...rounds {
                        for s in group { push(s, set: round) }
                        steps.append(Step(kind: .rest, label: "Rest", seconds: supersetRest))
                    }
                }
                for s in slots where s.pair == nil {
                    for set in 1...s.sets {
                        push(s, set: set)
                        if set < s.sets { steps.append(Step(kind: .rest, label: "Rest", seconds: finisherRest)) }
                    }
                }
                if steps.last?.kind == .rest { steps.removeLast() }
            }
        }
        steps.append(Step(kind: .finish, label: "Done"))
        return steps
    }
}
