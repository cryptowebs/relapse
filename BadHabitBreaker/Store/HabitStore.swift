import Foundation
import Combine
import UserNotifications

@MainActor
final class HabitStore: ObservableObject {
    @Published private(set) var state = AppState()
    private var isLoaded = false
    
    init() {
        Task { await load() }
    }
    
    func load() async {
        if isLoaded { return }
        state = await Persistence.shared.load()
        isLoaded = true
    }
    
    private func save() {
        Task { await Persistence.shared.save(state) }
    }
    
    func completeOnboarding(habit: HabitConfig) {
        state.habit = habit
        state.hasOnboarded = true
        save()
    }
    
    func logRelapse(trigger: String?, notes: String?) {
        let event = RelapseEvent(date: Date(), trigger: trigger, notes: notes)
        state.relapseLog.append(event)
        save()
    }
    
    func logSuccess() {
        state.successfulUrges += 1
        save()
    }
    
    func setReminders(enabled: Bool, times: [DateComponents]) {
        state.dailyRemindersEnabled = enabled
        state.reminderTimes = times
        save()
        Task {
            if enabled { await NotificationManager.shared.scheduleDailyReminders(times: times) }
            else { await UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
        }
    }
}
