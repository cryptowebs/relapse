import SwiftUI

@main
struct BadHabitBreakerApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.state.hasOnboarded {
                    HomeView()
                        .environmentObject(store)
                } else {
                    OnboardingView()
                        .environmentObject(store)
                }
            }
            .task {
                await NotificationManager.shared.requestAuthorization()
            }
        }
    }
}
