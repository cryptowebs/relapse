import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: HabitStore
    @State private var mood: Double = 3
    @State private var craving: Double = 4
    @State private var halt = Set<String>()
    @State private var notes = ""
    
    let HALT = ["Hungry","Angry","Lonely","Tired","Stressed","Bored"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Mood") {
                    HStack {
                        Text("Mood")
                        Slider(value: $mood, in: 1...5, step: 1)
                        Text("\(Int(mood))")
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                Section("Craving") {
                    HStack {
                        Text("Craving")
                        Slider(value: $craving, in: 0...10, step: 1)
                        Text("\(Int(craving))")
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                Section("HALT") {
                    WrapChips(items: HALT, selection: $halt)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 100)
                }
                Section {
                    Button {
                        store.logCheckIn(mood: Int(mood), craving: Int(craving), halt: Array(halt), notes: notes.isEmpty ? nil : notes)
                        Haptics.success()
                        dismiss()
                    } label: { Label("Save check-in", systemImage: "checkmark.circle.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Quick check-in")
        }
    }
}

private struct WrapChips: View {
    let items: [String]
    @Binding var selection: Set<String>
    var body: some View {
        FlowLayout(items: items) { item in
            let picked = selection.contains(item)
            Text(item)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 7)
                // Base material:
                .background(.thinMaterial, in: Capsule())
                // Conditional accent overlay (no Color/Material ternary):
                .overlay {
                    Capsule()
                        .fill(AppTheme.accent)
                        .opacity(picked ? 1 : 0)
                }
                // Subtle stroke on top:
                .overlay(
                    Capsule().strokeBorder(.white.opacity(0.08))
                )
                .onTapGesture {
                    if picked { selection.remove(item) } else { selection.insert(item) }
                }
        }
    }
}
