import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.openURL) private var openURL
    @State private var showFlow = false
    @State private var showSettings = false
    @State private var showCheckIn = false
    @State private var showRules = false
    @State private var showBuddies = false
    @State private var showTrends = false
    
    var habitName: String {
        let h = store.state.habit
        return h.type == .custom ? (h.customName ?? "My Habit") : h.type.display
    }
    var riskScore: Double {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeRisk: Double = (18...23).contains(hour) ? 0.55 : (14...17).contains(hour) ? 0.35 : 0.2
        let days = max(store.state.streakDays, 0)
        let streakRisk = days < 3 ? 0.5 : (days < 7 ? 0.35 : 0.15)
        return min(1.0, max(0.0, 0.6*timeRisk + 0.4*streakRisk))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "wind.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 34))
                                .foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(habitName).font(.title2.weight(.bold))
                                HStack(spacing: 8) {
                                    Label("\(store.state.streakDays) day\(store.state.streakDays == 1 ? "" : "s")", systemImage: "flame.fill")
                                        .foregroundStyle(.orange)
                                    Label("\(store.state.successfulUrges)", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }.font(.subheadline)
                            }
                            Spacer()
                        }
                    }.glassCard()
                    
                    RiskMeterView(score: riskScore)
                    
                    // plan
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Plan for an urge", systemImage: "shield.lefthalf.filled").font(.headline)
                        Text(store.state.habit.panicPlan)
                    }.glassCard()
                    
                    // quick actions grid
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ActionTile(title: "Check-in", icon: "square.and.pencil") { showCheckIn = true }
                            ActionTile(title: "If-Then", icon: "list.bullet.rectangle") { showRules = true }
                        }
                        HStack(spacing: 12) {
                            ActionTile(title: "Buddies", icon: "person.2.fill") { showBuddies = true }
                            ActionTile(title: "Trends", icon: "chart.bar.xaxis") { showTrends = true }
                        }
                    }
                    
                    // escape route if homeAddress set
                    if let addr = store.state.homeAddress, !addr.isEmpty {
                        Button {
                            let q = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "http://maps.apple.com/?daddr=\(q)") { openURL(url) }
                        } label: {
                            Label("Get me out of here (Maps to \(addr))", systemImage: "map.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button {
                        Haptics.lightTap(); showFlow = true
                    } label: {
                        Label("I’m having an urge", systemImage: "lifepreserver.fill")
                            .font(.title3.weight(.bold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Breaker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showFlow) { UrgeSheet().environmentObject(store) }
            .sheet(isPresented: $showSettings) { SettingsSheet().environmentObject(store) }
            .sheet(isPresented: $showCheckIn) { CheckInView().environmentObject(store) }
            .sheet(isPresented: $showRules) { IfThenLibraryView().environmentObject(store) }
            .sheet(isPresented: $showBuddies) { BuddySupportView().environmentObject(store) }
            .sheet(isPresented: $showTrends) { NavigationStack { TrendsView().environmentObject(store) } }
            .scrollIndicators(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
        }
    }
}

private struct ActionTile: View {
    let title: String; let icon: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }
}

private struct UrgeSheet: View {
    @EnvironmentObject var store: HabitStore
    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            UrgeFlowView()
                .presentationDetents([.medium, .large])
        }
    }
}

private struct SettingsSheet: View {
    @EnvironmentObject var store: HabitStore
    @State private var enabled: Bool = false
    @State private var address = ""
    @State private var exportURL: URL? = nil
    @State private var showShare = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily reminders", isOn: $enabled)
                        .onChange(of: enabled) { _ in
                            if !enabled { store.setReminders(enabled: false, times: []) }
                        }
                    if enabled {
                        Text("Adjust times in Settings → Reminders")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Escape route") {
                    TextField("Home address (for Maps)", text: $address)
                    Button("Save address") { store.setHomeAddress(address); Haptics.success() }
                }
                Section("Export") {
                    Button {
                        exportURL = store.exportJSON()
                        if exportURL != nil { showShare = true }
                    } label: { Label("Export data (JSON)", systemImage: "square.and.arrow.up") }
                }
            }
            .onAppear {
                enabled = store.state.dailyRemindersEnabled
                address = store.state.homeAddress ?? ""
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = exportURL { ShareView(url: url) }
        }
    }
}

private struct ShareView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
