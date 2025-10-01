import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: HabitStore
    @State private var enabled: Bool = false
    @State private var time1 = DateComponents(hour: 9, minute: 0)
    @State private var time2 = DateComponents(hour: 14, minute: 0)
    @State private var time3 = DateComponents(hour: 20, minute: 0)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily reminders", isOn: $enabled)
                    if enabled {
                        TimePickerRow(title: "Morning", comps: $time1)
                        TimePickerRow(title: "Afternoon", comps: $time2)
                        TimePickerRow(title: "Evening", comps: $time3)
                    }
                    Button("Save reminders") {
                        let times = [time1, time2, time3]
                        store.setReminders(enabled: enabled, times: times)
                    }
                }
                
                Section("Data") {
                    Text("Relapses logged: \(store.state.relapseLog.count)")
                    Button(role: .destructive) {
                        store.completeOnboarding(habit: store.state.habit)
                    } label: { Text("Reset onboarding (keeps data)") }
                }
            }
            .onAppear {
                enabled = store.state.dailyRemindersEnabled
                if store.state.reminderTimes.count >= 3 {
                    time1 = store.state.reminderTimes[0]
                    time2 = store.state.reminderTimes[1]
                    time3 = store.state.reminderTimes[2]
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct TimePickerRow: View {
    let title: String
    @Binding var comps: DateComponents
    @State private var date = Date()
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("", selection: Binding(get: {
                dateFromComponents(comps)
            }, set: { newDate in
                comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                date = newDate
            }), displayedComponents: .hourAndMinute)
            .labelsHidden()
        }
    }
    
    private func dateFromComponents(_ c: DateComponents) -> Date {
        var components = DateComponents()
        components.hour = c.hour ?? 9
        components.minute = c.minute ?? 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
