import SwiftUI

struct PlayerView: View {
    @ObservedObject var engine: SessionEngine
    let kinds: [SessionKind]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if engine.finished { finishView } else { activeView }
        }
        .navigationTitle(engine.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start(kinds: kinds) }
        .onDisappear { engine.stop() }
    }

    // MARK: active card

    private var activeView: some View {
        let u = engine.unit
        return ScrollView {
            VStack(spacing: 6) {
                HStack {
                    Text(format(engine.totalElapsed)).monospacedDigit()
                    Spacer()
                    Text("\(min(engine.index + 1, max(1, engine.units.count - 1))) / \(max(1, engine.units.count - 1))").foregroundStyle(.secondary)
                }
                .font(.caption2)

                if engine.paused {
                    Text("Paused").font(.caption).foregroundStyle(.orange)
                }

                switch u.kind {
                case .set:
                    if let ex = u.exercise {
                        Text(ex.name).font(.headline).multilineTextAlignment(.center)
                        Text(u.label + (u.partner.map { " · then \($0)" } ?? "")).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Text(ex.cue).font(.caption2).foregroundStyle(.orange).multilineTextAlignment(.center)
                        if ex.mode == .time { holdControls(ex) } else { repControls(ex) }
                    }
                case .lead:
                    Text("Core finisher").font(.headline)
                    ring(progress: engine.progress, text: "\(Int(ceil(engine.remaining)))", color: .orange)
                    Text("Get into position for \(u.coreMoves.first?.name ?? "the first move"). Low back stays down the whole circuit.").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                case .interval:
                    if let ex = u.exercise {
                        Text(ex.name).font(.headline).multilineTextAlignment(.center)
                        Text(u.label + (ex.perSide ? " · switch halfway" : "")).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Text(ex.cue).font(.caption2).foregroundStyle(.orange).multilineTextAlignment(.center)
                        intervalRing
                        if !engine.resting && engine.phase == .hold {
                            Button("Done early") { engine.doneEarly() }.buttonStyle(.bordered)
                        }
                    }
                case .finish:
                    EmptyView()
                }

                if engine.resting { restBar } else if !engine.nextLabel.isEmpty {
                    Text("Next: \(engine.nextLabel)").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                HStack {
                    Button(engine.paused ? "Resume" : "Pause") { engine.togglePause() }.buttonStyle(.bordered)
                    Button("Skip") { engine.skip() }.buttonStyle(.bordered)
                }
                Button("End and save") { engine.endNow() }.buttonStyle(.bordered).tint(.red)
            }
            .padding(.horizontal, 4)
        }
    }

    private func holdControls(_ ex: Exercise) -> some View {
        VStack(spacing: 6) {
            switch engine.phase {
            case .idle:
                ring(progress: engine.resting ? restProgress : 0,
                     text: engine.resting ? "\(Int(ceil(engine.restRemaining)))" : "\(ex.target)",
                     color: engine.resting ? .green : .blue)
                Text(ex.perSide ? "Left first, then right. \(ex.target)s each." : "Hold for \(ex.target)s.").font(.caption2).foregroundStyle(.secondary)
                Button(engine.resting ? "Resting…" : "Start hold") { engine.startHold() }
                    .buttonStyle(.borderedProminent).tint(.blue).disabled(engine.resting)
            case .switchSides:
                ring(progress: engine.progress, text: "\(Int(ceil(engine.remaining)))", color: .orange)
                Text("Switch sides").font(.caption).foregroundStyle(.orange)
            case .hold:
                ring(progress: engine.progress, text: "\(Int(ceil(engine.remaining)))", color: .blue)
                if ex.perSide { Text(engine.side).font(.caption2).foregroundStyle(.secondary) }
                HStack {
                    Button("+10s") { engine.extendHold(10) }.buttonStyle(.bordered)
                    Button("Done") { engine.doneEarly() }.buttonStyle(.bordered)
                }
            }
        }
    }

    private func repControls(_ ex: Exercise) -> some View {
        VStack(spacing: 6) {
            if ex.perSide {
                stepper(title: "Left", value: engine.repsLeft, which: "L")
                stepper(title: "Right", value: engine.repsRight, which: "R")
            } else {
                stepper(title: "Reps", value: engine.reps, which: "A")
            }
            Text("Target \(ex.target). Stop 1-3 reps short of failure.").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(engine.resting ? "Resting…" : "Log set \(engine.unit.set)") { engine.logSet() }
                .buttonStyle(.borderedProminent).tint(.blue).disabled(engine.resting)
        }
    }

    private func stepper(title: String, value: Int, which: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.caption2).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Button { engine.adjust(which, by: -1) } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text("\(value)").font(.system(size: 26, weight: .bold, design: .rounded)).monospacedDigit().frame(minWidth: 34)
            Button { engine.adjust(which, by: 1) } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }

    private var intervalRing: some View {
        Group {
            if engine.resting {
                ring(progress: restProgress, text: "\(Int(ceil(engine.restRemaining)))", color: .green)
            } else if engine.phase == .hold {
                ring(progress: engine.progress, text: "\(Int(ceil(engine.remaining)))", color: .orange)
            } else {
                ring(progress: 0, text: "\(Int(engine.unit.seconds))", color: .orange)
            }
        }
    }

    private var restProgress: Double {
        engine.restTotal > 0 ? 1 - engine.restRemaining / engine.restTotal : 1
    }

    private var restBar: some View {
        HStack(spacing: 8) {
            Text("\(Int(ceil(engine.restRemaining)))").font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit()
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.restLabel).font(.caption).bold()
                Text("Next: \(engine.unit.exercise?.name ?? engine.unit.label)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Button("+15") { engine.addRest(15) }.buttonStyle(.bordered).font(.caption2)
            Button("Skip") { engine.skipRest() }.buttonStyle(.borderedProminent).tint(.green).font(.caption2)
        }
        .padding(6)
        .background(Color.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func ring(progress: Double, text: String, color: Color) -> some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(text).font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit()
        }
        .frame(width: 96, height: 96)
    }

    // MARK: finish

    private var finishView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Done").font(.headline)
                Text("Total \(format(engine.totalElapsed))").font(.caption).monospacedDigit()
                if engine.coreTotal > 0 {
                    Text("Core: \(engine.coreDone) of \(engine.coreTotal) intervals").font(.caption)
                }
                Text("Rate it 1-10 and log it in the phone app. Progression lives there.")
                    .font(.caption2).foregroundStyle(.secondary)
                ForEach(Array(engine.log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption2)
                }
                Button("Close") { dismiss() }.buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 4)
        }
    }

    private func format(_ seconds: Double) -> String {
        let t = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
