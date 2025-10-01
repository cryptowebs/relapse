import SwiftUI

@main
struct BadHabitBreakerApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppTheme.bgGradient.ignoresSafeArea()
                Group {
                    if store.state.hasOnboarded { MainTabsView().environmentObject(store) } else { OnboardingView().environmentObject(store) }
                }
            }
            .preferredColorScheme(.dark)
            .tint(AppTheme.accent)
            .task { await NotificationManager.shared.requestAuthorization() }
        }
    }
}
