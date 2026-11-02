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
}

struct Slot {
    let label: String
    let sets: Int
    let pair: String?      // superset group within a day; nil for straight sets
    let exercise: Exercise
}

enum UnitKind { case set, lead, interval, finish }

/// One card in the session: a single set of an exercise, the core lead-in,
/// one core interval, or the finish. Rest is a property of the unit before it.
struct Unit: Identifiable {
    let id = UUID()
    let kind: UnitKind
    var exercise: Exercise? = nil
    var label: String = ""
    var set: Int = 0
    var sets: Int = 0
    var round: Int = 0
    var rounds: Int = 0
    var move: Int = 0
    var moves: Int = 0
    var seconds: Double = 0
    var restAfter: Double = 0
    var restLabel: String = "Rest"
    var partner: String? = nil
    var coreMoves: [Exercise] = []
}

enum SessionKind {
    case block, dayA, dayB, core5, core10

    var title: String {
        switch self {
        case .block: return "Block"
        case .dayA: return "Day A"
        case .dayB: return "Day B"
        case .core5, .core10: return "Core"
        }
    }
}

enum Program {
    static let blockRest: Double = 15
    static let supersetRest: Double = 60
    static let finisherRest: Double = 45
    static let boundaryRest: Double = 20

    static let block: [Slot] = [
        Slot(label: "Block 1", sets: 2, pair: nil, exercise: Exercise(name: "Half-kneeling hip flexor stretch", cue: "Tuck, squeeze the back glute, then lean", mode: .time, perSide: true, target: 45)),
        Slot(label: "Block 2", sets: 2, pair: nil, exercise: Exercise(name: "Dead bug", cue: "Low back glued to the floor, long exhale", mode: .reps, perSide: true, target: 8)),
        Slot(label: "Block 3", sets: 2, pair: nil, exercise: Exercise(name: "Bird dog", cue: "Tabletop back, 5-second hold", mode: .reps, perSide: true, target: 6)),
        Slot(label: "Block 4", sets: 2, pair: nil, exercise: Exercise(name: "Side plank", cue: "Straight line, hips slightly forward", mode: .time, perSide: true, target: 30)),
        Slot(label: "Block 5", sets: 2, pair: nil, exercise: Exercise(name: "Glute bridge", cue: "Tuck, drive heels, 2-second squeeze", mode: .reps, perSide: false, target: 12)),
    ]

    static let dayA: [Slot] = [
        Slot(label: "A1", sets: 3, pair: "A", exercise: Exercise(name: "Push-up", cue: "Glutes squeezed, one straight line", mode: .reps, perSide: false, target: 10)),
        Slot(label: "A2", sets: 3, pair: "A", exercise: Exercise(name: "Bulgarian split squat", cue: "Tuck the pelvis, squeeze the rear glute", mode: .reps, perSide: true, target: 8)),
        Slot(label: "B1", sets: 3, pair: "B", exercise: Exercise(name: "Pike push-up", cue: "Hips high, head between the hands", mode: .reps, perSide: false, target: 6)),
        Slot(label: "B2", sets: 3, pair: "B", exercise: Exercise(name: "Reverse crunch", cue: "Curl with the abs, lower slowly", mode: .reps, perSide: false, target: 10)),
    ]

    static let dayB: [Slot] = [
        Slot(label: "A1", sets: 3, pair: "A", exercise: Exercise(name: "Inverted row", cue: "Body straight, squeeze the shoulder blades", mode: .reps, perSide: false, target: 8)),
        Slot(label: "A2", sets: 3, pair: "A", exercise: Exercise(name: "Single-leg RDL", cue: "Torso and back leg move as one", mode: .reps, perSide: true, target: 8)),
        Slot(label: "B1", sets: 3, pair: "B", exercise: Exercise(name: "Hip thrust", cue: "Chin tucked, tilt back and squeeze", mode: .reps, perSide: false, target: 10)),
        Slot(label: "B2", sets: 3, pair: "B", exercise: Exercise(name: "Towel hamstring curl", cue: "Hips up, slide in and out", mode: .reps, perSide: false, target: 8)),
        Slot(label: "C", sets: 2, pair: nil, exercise: Exercise(name: "Reverse hyper", cue: "To the line, no higher", mode: .reps, perSide: false, target: 12)),
    ]

    // Core finisher pool: every move keeps the low back down. Rotated by day.
    static let coreAntiExtension: [Exercise] = [
        Exercise(name: "Hollow hold", cue: "Low back pressed down the whole time", mode: .time, perSide: false, target: 40),
        Exercise(name: "Tucked forearm plank", cue: "Tuck hard, squeeze everything", mode: .time, perSide: false, target: 40),
        Exercise(name: "Reverse crunch", cue: "Curl with the abs, lower slowly", mode: .reps, perSide: false, target: 12),
        Exercise(name: "Bent-knee leg lower", cue: "Stop where the back wants to lift", mode: .reps, perSide: false, target: 10),
        Exercise(name: "Hollow rock", cue: "Rock without bending", mode: .reps, perSide: false, target: 12),
        Exercise(name: "Plank hip tuck", cue: "Tuck hard, hold two seconds", mode: .reps, perSide: false, target: 10),
        Exercise(name: "Bear hold", cue: "Knees an inch up, back flat", mode: .time, perSide: false, target: 40),
        Exercise(name: "Dead bug, 3-second lower", cue: "Three seconds down, back stays flat", mode: .reps, perSide: true, target: 8),
    ]
    static let coreLateral: [Exercise] = [
        Exercise(name: "Side plank", cue: "Straight line, hips slightly forward", mode: .time, perSide: true, target: 40),
        Exercise(name: "Side plank hip dip", cue: "Lower slowly, lift to the line", mode: .reps, perSide: true, target: 10),
        Exercise(name: "Copenhagen plank, knee on couch", cue: "Squeeze the inner thigh, hips up", mode: .time, perSide: true, target: 40),
        Exercise(name: "Plank arm reach", cue: "Reach, hips dead still", mode: .reps, perSide: true, target: 8),
        Exercise(name: "Plank shoulder taps", cue: "Hips dead still", mode: .reps, perSide: true, target: 10),
    ]
    static let coreStable: [Exercise] = [
        Exercise(name: "Bird dog, 10-second hold", cue: "Hips level, long slow breath", mode: .reps, perSide: true, target: 5),
        Exercise(name: "Slow mountain climber", cue: "Hips still, knee in slowly", mode: .reps, perSide: true, target: 10),
        Exercise(name: "Dead bug hold", cue: "Hold, breathe out, back glued down", mode: .time, perSide: true, target: 40),
    ]

    static func coreMoves(ten: Bool) -> [Exercise] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        func pick(_ pool: [Exercise], _ n: Int) -> Exercise { pool[(day * 7 + n * 3) % pool.count] }
        var moves = [pick(coreAntiExtension, 0), pick(coreLateral, 1), pick(coreStable, 2)]
        if ten {
            let rest = coreAntiExtension.filter { $0.name != moves[0].name }
            moves.append(pick(rest, 3))
        }
        return moves
    }

    static func title(for kinds: [SessionKind]) -> String {
        kinds.map { $0.title }.joined(separator: " + ")
    }

    /// Same sequencing as the phone app: Block in order with short breathers,
    /// supersets in rounds with a rest after each pair, then the core circuit.
    static func units(for kinds: [SessionKind]) -> [Unit] {
        var units: [Unit] = []

        for kind in kinds {
            switch kind {
            case .block:
                for (i, slot) in block.enumerated() {
                    for set in 1...slot.sets {
                        let last = set == slot.sets && i == block.count - 1
                        units.append(Unit(kind: .set, exercise: slot.exercise, label: "\(slot.label) · Set \(set) of \(slot.sets)", set: set, sets: slot.sets, restAfter: last ? 0 : blockRest, restLabel: "Breathe"))
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
                        for (idx, s) in group.enumerated() {
                            let partner = group[(idx + 1) % group.count].exercise.name
                            let lastInRound = idx == group.count - 1
                            units.append(Unit(kind: .set, exercise: s.exercise, label: "Superset \(p) · Round \(round) of \(rounds)", set: round, sets: rounds, round: round, rounds: rounds, restAfter: lastInRound ? supersetRest : 0, restLabel: "Rest", partner: partner))
                        }
                    }
                }
                for s in slots where s.pair == nil {
                    for set in 1...s.sets {
                        units.append(Unit(kind: .set, exercise: s.exercise, label: "\(s.label) · Set \(set) of \(s.sets)", set: set, sets: s.sets, restAfter: set < s.sets ? finisherRest : 0))
                    }
                }
                if !units.isEmpty { units[units.count - 1].restAfter = 0 }
            case .core5, .core10:
                let ten = kind == .core10
                let moves = coreMoves(ten: ten)
                let work: Double = ten ? 50 : 40
                let rest: Double = 15
                let rounds = 2
                units.append(Unit(kind: .lead, label: "Core finisher", seconds: 10, coreMoves: moves))
                for round in 1...rounds {
                    for (mi, ex) in moves.enumerated() {
                        let last = round == rounds && mi == moves.count - 1
                        units.append(Unit(kind: .interval, exercise: ex, label: "Round \(round) of \(rounds) · Move \(mi + 1) of \(moves.count)", round: round, rounds: rounds, move: mi + 1, moves: moves.count, seconds: work, restAfter: last ? 0 : rest))
                    }
                }
            }
            // a breather between sections
            if let last = units.last, last.restAfter == 0, kind != kinds.last {
                units[units.count - 1].restAfter = boundaryRest
                units[units.count - 1].restLabel = "Breathe"
            }
        }
        units.append(Unit(kind: .finish, label: "Done"))
        return units
    }
}
