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

// NEW: User-saved urges they want to prevent
struct UserUrge: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: HabitType
    var customName: String?
    var whatDoingNow: String?
    var whatWorks: [String] = []
    var whatDoesnt: [String] = []
    var temptations: [String] = []
    var currentStreak: Int = 0
    var lastRelapseDate: Date?
    var createdAt: Date = Date()
    var displayName: String {
        type == .custom ? (customName ?? "Custom") : type.display
    }
}

// NEW: SOS feedback tallies (simple counters)
struct UrgeFeedback: Codable {
    var helpedCount: Int = 0
    var stillUrgeCount: Int = 0
}

/** Daily check-ins (EMA-style) */
struct CheckIn: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = Date()
    var mood: Int      // 1–5
    var craving: Int   // 0–10
    var halt: [String] // e.g., ["Hungry","Tired"]
    var notes: String?
}

struct IfThenRule: Identifiable, Codable, Equatable {
    var id = UUID()
    var cue: String
    var action: String
    var isActive: Bool = true
}

struct BuddyContact: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var phone: String // e.g. +1xxxxxxxxxx
}

struct AppState: Codable {
    var hasOnboarded: Bool = false
    var habit: HabitConfig = HabitConfig(type: .nicotine, customName: nil, triggers: [], panicPlan: "Step outside + cold water + text accountability buddy.")
    var relapseLog: [RelapseEvent] = []
    var successfulUrges: Int = 0
    var dailyRemindersEnabled: Bool = false
    var reminderTimes: [DateComponents] = []
    // Extended
    var ifThenRules: [IfThenRule] = []
    var buddies: [BuddyContact] = []
    var checkIns: [CheckIn] = []
    var homeAddress: String? = nil
    // NEW:
    var myUrges: [UserUrge] = []
    var gameHighScore: Int = 0
    var sosFeedback: UrgeFeedback = .init()
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
