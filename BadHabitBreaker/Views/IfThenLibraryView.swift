import SwiftUI

struct IfThenLibraryView: View {
    @EnvironmentObject var store: HabitStore
    @State private var cue = ""
    @State private var action = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Add a rule") {
                    TextField("If (cue): e.g., Payday 5pm", text: $cue)
                    TextField("Then (action): e.g., go straight home via Elm St", text: $action)
                    Button {
                        guard !cue.trimmingCharacters(in: .whitespaces).isEmpty,
                              !action.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        store.addIfThen(cue: cue, action: action)
                        cue = ""; action = ""
                        Haptics.success()
                    } label: { Label("Save rule", systemImage: "plus.circle.fill") }
                    .buttonStyle(.borderedProminent)
                }
                
                Section("My rules") {
                    if store.state.ifThenRules.isEmpty {
                        Text("No rules yet. Add your top 1–3 high-leverage If–Then plans.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.state.ifThenRules) { rule in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Toggle("", isOn: Binding(
                                    get: { rule.isActive },
                                    set: { _ in store.toggleIfThen(rule.id) }
                                ))
                                .labelsHidden()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("If \(rule.cue),").font(.subheadline).foregroundStyle(.secondary)
                                    Text("then \(rule.action).").font(.headline)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    store.removeIfThen(rule.id)
                                } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("If-Then rules")
        }
    }
}
