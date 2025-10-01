import Foundation
import Combine
import UserNotifications

@MainActor
final class HabitStore: ObservableObject {
    @Published private(set) var state = AppState()
    private var isLoaded = false
    
    init() { Task { await load() } }
    
    func load() async {
        if isLoaded { return }
        state = await Persistence.shared.load()
        isLoaded = true
    }
    private func save() { Task { await Persistence.shared.save(state) } }
    
    // Onboarding
    func completeOnboarding(habit: HabitConfig) {
        state.habit = habit
        state.hasOnboarded = true
        save()
    }
    
    // Core logs
    func logRelapse(trigger: String?, notes: String?) {
        state.relapseLog.append(RelapseEvent(date: Date(), trigger: trigger, notes: notes))
        save()
    }
    func logSuccess() {
        state.successfulUrges += 1
        save()
    }
    
    // Reminders
    func setReminders(enabled: Bool, times: [DateComponents]) {
        state.dailyRemindersEnabled = enabled
        state.reminderTimes = times
        save()
        Task {
            if enabled {
                NotificationManager.shared.scheduleDailyReminders(times: times)
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    // If–Then rules
    func addIfThen(cue: String, action: String) {
        state.ifThenRules.append(.init(cue: cue, action: action))
        save()
    }
    func toggleIfThen(_ id: UUID) {
        guard let i = state.ifThenRules.firstIndex(where: {$0.id == id}) else { return }
        state.ifThenRules[i].isActive.toggle()
        save()
    }
    func removeIfThen(_ id: UUID) {
        state.ifThenRules.removeAll{$0.id == id}
        save()
    }
    
    // Buddies
    func addBuddy(name: String, phone: String) {
        state.buddies.append(.init(name: name, phone: phone))
        save()
    }
    func removeBuddy(_ id: UUID) {
        state.buddies.removeAll{$0.id == id}
        save()
    }
    
    // Check-ins
    func logCheckIn(mood: Int, craving: Int, halt: [String], notes: String?) {
        state.checkIns.append(.init(mood: mood, craving: craving, halt: halt, notes: notes))
        save()
    }
    
    // Home address
    func setHomeAddress(_ addr: String?) {
        state.homeAddress = (addr?.isEmpty == true) ? nil : addr
        save()
    }
    
    // Export
    func exportJSON() -> URL? {
        do {
            let data = try JSONEncoder().encode(state)
            return try DataExporter.writeJSON(data: data, fileName: "BadHabitBreakerExport.json")
        } catch {
            print("Export error:", error); return nil
        }
    }
    
    // NEW: My Urges
    func addUrge(_ u: UserUrge) {
        state.myUrges.append(u)
        save()
    }
    func updateUrge(_ u: UserUrge) {
        guard let idx = state.myUrges.firstIndex(where: {$0.id == u.id}) else { return }
        state.myUrges[idx] = u
        save()
    }
    func removeUrge(id: UUID) {
        state.myUrges.removeAll { $0.id == id }
        save()
    }
    func logUrgeRelapse(id: UUID) {
        guard let idx = state.myUrges.firstIndex(where: {$0.id == id}) else { return }
        state.myUrges[idx].lastRelapseDate = Date()
        state.myUrges[idx].currentStreak = 0
        save()
    }
    func incrementUrgeStreaksDaily() {
        // simple example hook if you later add a daily job
        for i in state.myUrges.indices {
            state.myUrges[i].currentStreak += 1
        }
        save()
    }
    
    // NEW: Mini game high score
    func submitGameScore(_ score: Int) {
        if score > state.gameHighScore {
            state.gameHighScore = score
            save()
        }
    }
    
    // NEW: SOS feedback
    func recordSOSFeedback(helped: Bool) {
        if helped { state.sosFeedback.helpedCount += 1 }
        else { state.sosFeedback.stillUrgeCount += 1 }
        save()
    }
}
