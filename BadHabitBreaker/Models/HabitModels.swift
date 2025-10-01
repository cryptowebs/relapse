import Foundation

enum HabitType: String, CaseIterable, Identifiable, Codable {
    case nicotine, sugar, doomscrolling, alcohol, gambling, porn, custom
    var id: String { rawValue }
    
    var display: String {
        switch self {
        case .nicotine: return "Nicotine"
        case .sugar: return "Sugar"
        case .doomscrolling: return "Doomscrolling"
        case .alcohol: return "Alcohol"
        case .gambling: return "Gambling"
        case .porn: return "Adult Content"
        case .custom: return "Custom"
        }
    }
}

struct HabitConfig: Codable, Equatable {
    var type: HabitType
    var customName: String?
    var triggers: [String]
    var panicPlan: String
}

struct RelapseEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var trigger: String?
    var notes: String?
}

struct AppState: Codable {
    var hasOnboarded: Bool = false
    var habit: HabitConfig = HabitConfig(type: .nicotine, customName: nil, triggers: [], panicPlan: "Step outside + cold water + text accountability buddy.")
    var relapseLog: [RelapseEvent] = []
    var successfulUrges: Int = 0
    var dailyRemindersEnabled: Bool = false
    var reminderTimes: [DateComponents] = []
}

extension Array where Element == RelapseEvent {
    var lastRelapseDate: Date? { self.sorted(by: { $0.date > $1.date }).first?.date }
}

extension AppState {
    var streakDays: Int {
        guard let last = relapseLog.lastRelapseDate else { return daysBetween(from: installAnchorDate(), to: Date()) }
        return daysBetween(from: last, to: Date())
    }
    
    private func installAnchorDate() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
}

func daysBetween(from: Date, to: Date) -> Int {
    let cal = Calendar.current
    let start = cal.startOfDay(for: from)
    let end = cal.startOfDay(for: to)
    return cal.dateComponents([.day], from: start, to: end).day ?? 0
}
