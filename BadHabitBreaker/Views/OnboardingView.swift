import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: HabitStore
    
    @State private var selected: HabitType = .nicotine
    @State private var customName: String = ""
    @State private var triggersText: String = "Stress; Boredom; After meals"
    @State private var panicPlan: String = "Step outside, 10 deep breaths, splash cold water, text a friend"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Habit", selection: $selected) {
                        ForEach(HabitType.allCases) { t in
                            Text(t.display).tag(t)
                        }
                    }
                    if selected == .custom {
                        TextField("Name your habit", text: $customName)
                    }
                } header: {
                    Text("Pick the habit")
                }
                
                Section {
                    TextField("Semicolon-separated", text: $triggersText)
                        .textInputAutocapitalization(.never)
                        .font(.callout)
                } header: {
                    Text("Your triggers")
                }
                
                Section {
                    TextEditor(text: $panicPlan).frame(minHeight: 110)
                } header: {
                    Text("Panic plan")
                }
                
                Section {
                    Button {
                        let triggers = triggersText
                            .split(separator: ";")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let config = HabitConfig(
                            type: selected,
                            customName: selected == .custom ? (customName.isEmpty ? "My Habit" : customName) : nil,
                            triggers: triggers,
                            panicPlan: panicPlan.isEmpty ? "Breathe + Cold water + Text friend" : panicPlan
                        )
                        store.completeOnboarding(habit: config)
                    } label: {
                        Label("Start", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowInsets(EdgeInsets())
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Set up")
        }
        .tint(AppTheme.accent)
    }
}
