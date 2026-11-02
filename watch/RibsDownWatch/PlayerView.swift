import SwiftUI

struct PlayerView: View {
    @ObservedObject var engine: SessionEngine
    let kinds: [SessionKind]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if engine.finished {
                finishView
            } else {
                activeView
            }
        }
        .navigationTitle(engine.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start(kinds: kinds) }
        .onDisappear { engine.stop() }
    }

    private var activeView: some View {
        let st = engine.step
        return ScrollView {
            VStack(spacing: 6) {
                Text(format(engine.totalElapsed))
                    .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                ring(for: st)
                switch st.kind {
                case .exercise:
                    if let ex = st.exercise {
                        Text(ex.name).font(.headline).multilineTextAlignment(.center)
                        Text("Set \(st.set) of \(st.sets)" + (st.side.map { " · \($0)" } ?? ""))
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(ex.cue).font(.caption2).foregroundStyle(.orange).multilineTextAlignment(.center)
                        if ex.mode == .reps {
                            HStack(spacing: 12) {
                                Button { engine.adjust(-1) } label: { Image(systemName: "minus") }
                                Text("\(engine.reps)")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .frame(minWidth: 44)
                                Button { engine.adjust(1) } label: { Image(systemName: "plus") }
                            }
                            Button("Done") { engine.done() }
                                .buttonStyle(.borderedProminent).tint(.blue)
                        }
                        Button("Skip") { engine.skip() }.buttonStyle(.bordered)
                    }
                case .rest, .switchSides:
                    Text(st.label).font(.headline)
                    if let next = engine.nextExercise {
                        Text("Next: \(next.name)").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Text(next.cue).font(.caption2).foregroundStyle(.orange).multilineTextAlignment(.center)
                    }
                    HStack {
                        Button("+15s") { engine.addRest(15) }.buttonStyle(.bordered)
                        Button("Skip") { engine.advance(logging: false) }
                            .buttonStyle(.borderedProminent).tint(.green)
                    }
                case .finish:
                    EmptyView()
                }
                Button(engine.paused ? "Resume" : "Pause") { engine.togglePause() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 4)
        }
    }

    private var finishView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Done").font(.headline)
                Text("Total \(format(engine.totalElapsed))").font(.caption).monospacedDigit()
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

    private func ring(for st: Step) -> some View {
        let data = ringData(st)
        return ZStack {
            Circle().stroke(Color.gray.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: data.progress)
                .stroke(data.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(data.text)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 104, height: 104)
    }

    private func ringData(_ st: Step) -> (progress: Double, text: String, color: Color) {
        switch st.kind {
        case .exercise:
            guard let ex = st.exercise else { return (0, "", .blue) }
            if ex.mode == .time {
                let remaining = max(0, Double(ex.target) - engine.stepElapsed)
                return (min(1, engine.stepElapsed / Double(ex.target)), "\(Int(ceil(remaining)))", .blue)
            }
            return (min(1, Double(engine.reps) / Double(max(1, ex.target))), "\(Int(engine.stepElapsed))s", .blue)
        case .rest, .switchSides:
            let remaining = max(0, st.seconds - engine.stepElapsed)
            let progress = st.seconds > 0 ? min(1, engine.stepElapsed / st.seconds) : 1
            return (progress, "\(Int(ceil(remaining)))", .green)
        case .finish:
            return (1, "Done", .green)
        }
    }

    private func format(_ seconds: Double) -> String {
        let t = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
