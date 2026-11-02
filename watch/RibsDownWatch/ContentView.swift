import SwiftUI

struct ContentView: View {
    @StateObject private var engine = SessionEngine()

    var body: some View {
        NavigationStack {
            List {
                Section("Floor work") {
                    sessionRow("Block only", "10 min, the part that matters most", [.block])
                    sessionRow("Block + Day A", "Push + legs, about 27 min", [.block, .dayA])
                    sessionRow("Block + Day B", "Pull + hinge, about 27 min", [.block, .dayB])
                    sessionRow("Day A only", "If the Block is already done", [.dayA])
                    sessionRow("Day B only", "If the Block is already done", [.dayB])
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
                    Text("Ribs down, glutes on. Ratings and progression are logged in the phone app.")
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
