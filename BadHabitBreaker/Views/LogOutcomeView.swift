import SwiftUI

struct LogOutcomeView: View {
    var onSuccess: () -> Void
    var onRelapse: (_ trigger: String?, _ notes: String?) -> Void
    
    @EnvironmentObject var store: HabitStore
    @State private var outcome: Int = 0 // 0 success, 1 relapse
    @State private var trigger: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        Form {
            Section("Outcome") {
                Picker("Result", selection: $outcome) {
                    Text("I rode out the urge ✅").tag(0)
                    Text("I relapsed ❌").tag(1)
                }.pickerStyle(.segmented)
            }
            Section("What triggered it?") {
                TextField("Optional (e.g., stress, boredom…)", text: $trigger)
            }
            Section("Notes") {
                TextEditor(text: $notes).frame(minHeight: 100)
            }
            Section {
                Button("Save") {
                    if outcome == 0 { onSuccess() }
                    else { onRelapse(trigger.isEmpty ? nil : trigger, notes.isEmpty ? nil : notes) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Log outcome")
    }
}
