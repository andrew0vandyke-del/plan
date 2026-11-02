import SwiftUI

struct ContentView: View {
    @StateObject private var engine = SessionEngine()

    var body: some View {
        NavigationStack {
            List {
                Section("Floor work") {
                    sessionRow("Block only", "10 min, the part that matters most", [.block])
                    sessionRow("Block + Day A + Core", "Push + legs, about 32 min", [.block, .dayA, .core5])
                    sessionRow("Block + Day B + Core", "Pull + hinge, about 32 min", [.block, .dayB, .core5])
                    sessionRow("Day A only", "If the Block is already done", [.dayA])
                    sessionRow("Day B only", "If the Block is already done", [.dayB])
                }
                Section("Core finisher") {
                    sessionRow("Core, 5 min", "3 moves, 2 rounds, 40s on / 15s off", [.core5])
                    sessionRow("Core, 10 min", "4 moves, 2 rounds, 50s on / 15s off", [.core10])
                }
                Section("Cardio") {
                    NavigationLink {
                        RunView()
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Run timer")
                            Text("Mile splits with a tap").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Text("Ribs down, glutes on. Log sets here; rate and save the session in the phone app.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ribs Down")
        }
    }

    private func sessionRow(_ title: String, _ subtitle: String, _ kinds: [SessionKind]) -> some View {
        NavigationLink {
            PlayerView(engine: engine, kinds: kinds)
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
