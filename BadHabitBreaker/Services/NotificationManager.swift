import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func scheduleDailyReminders(times: [DateComponents]) async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        for (idx, comps) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Check-in"
            content.body = "Quick urge check: 2 mins of breathing beats 20 mins of regret."
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "daily-\(idx)", content: content, trigger: trigger)
            try? await center.add(req)
        }
    }
}
