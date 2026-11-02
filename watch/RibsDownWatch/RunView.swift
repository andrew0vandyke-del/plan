import SwiftUI
import WatchKit

/// A simple run stopwatch with mile splits. For heart rate and Apple Health,
/// run the Watch's own Workout app alongside and log the result in the phone app.
struct RunView: View {
    @State private var running = false
    @State private var startedAt: Date? = nil
    @State private var accumulated: Double = 0
    @State private var elapsed: Double = 0
    @State private var splits: [Double] = []
    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(format(elapsed))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Ribs stacked, short quick steps").font(.caption2).foregroundStyle(.orange)
                HStack {
                    Button(running ? "Pause" : (accumulated == 0 ? "Start" : "Resume")) { toggle() }
                        .buttonStyle(.borderedProminent).tint(running ? .orange : .green)
                    Button("Mile") { lap() }.buttonStyle(.bordered).disabled(!running)
                }
                if !splits.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(splits.enumerated()), id: \.offset) { i, s in
                            Text("Mile \(i + 1): \(format(s))").font(.caption2).monospacedDigit()
                        }
                    }
                }
                Button("Reset") { reset() }.buttonStyle(.bordered).disabled(running)
                Text("Log the distance, time and rating in the phone app afterwards.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Run")
        .onReceive(ticker) { _ in
            if running, let s = startedAt { elapsed = accumulated + Date().timeIntervalSince(s) }
        }
    }

    private func toggle() {
        if running {
            accumulated += Date().timeIntervalSince(startedAt ?? Date())
            startedAt = nil
            running = false
            WKInterfaceDevice.current().play(.stop)
        } else {
            startedAt = Date()
            running = true
            WKInterfaceDevice.current().play(.start)
        }
    }

    private func lap() {
        let previous = splits.reduce(0, +)
        splits.append(elapsed - previous)
        WKInterfaceDevice.current().play(.success)
    }

    private func reset() {
        accumulated = 0
        elapsed = 0
        splits = []
        startedAt = nil
    }

    private func format(_ seconds: Double) -> String {
        let t = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
