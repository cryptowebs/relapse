#!/usr/bin/env bash
set -euo pipefail

# === 0) POINT THIS TO YOUR XCODE PROJECT FOLDER ===
PROJ="$HOME/Desktop/BadHabitBreaker"     # folder that contains BadHabitBreaker.xcodeproj
APP_DIR="$PROJ/BadHabitBreaker"      # default source dir that Xcode made

# sanity
if [ ! -d "$APP_DIR" ]; then
  echo "✗ Couldn't find $APP_DIR. Create an iOS App project named 'BadHabitBreaker' first, or update PROJ."
  exit 1
fi

mkdir -p "$APP_DIR/Models" "$APP_DIR/Services" "$APP_DIR/Store" "$APP_DIR/Views/UrgeFlow" "$APP_DIR/Resources"
rm -f "$APP_DIR/ContentView.swift"

# --- BadHabitBreakerApp.swift ---
cat > "$APP_DIR/BadHabitBreakerApp.swift" <<'SWIFT'
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
SWIFT

# --- Models/HabitModels.swift ---
cat > "$APP_DIR/Models/HabitModels.swift" <<'SWIFT'
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
SWIFT

# --- Models/Persistence.swift ---
cat > "$APP_DIR/Models/Persistence.swift" <<'SWIFT'
import Foundation

actor Persistence {
    static let shared = Persistence()
    private let url: URL = {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return u.appendingPathComponent("app_state.json")
    }()
    
    func load() -> AppState {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AppState.self, from: data)
        } catch {
            return AppState()
        }
    }
    
    func save(_ state: AppState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Persist error:", error)
        }
    }
}
SWIFT

# --- Services/NotificationManager.swift ---
cat > "$APP_DIR/Services/NotificationManager.swift" <<'SWIFT'
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
SWIFT

# --- Store/HabitStore.swift ---
cat > "$APP_DIR/Store/HabitStore.swift" <<'SWIFT'
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
SWIFT

# --- Views/OnboardingView.swift ---
cat > "$APP_DIR/Views/OnboardingView.swift" <<'SWIFT'
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: HabitStore
    
    @State private var selected: HabitType = .nicotine
    @State private var customName: String = ""
    @State private var triggersText: String = "Stress; Boredom; After meals"
    @State private var panicPlan: String = "Step outside, 10 deep breaths, splash cold water, text a friend"

    var body: some View {
        NavigationStack {
            Form {
                Section("Pick the habit") {
                    Picker("Habit", selection: $selected) {
                        ForEach(HabitType.allCases) { t in
                            Text(t.display).tag(t)
                        }
                    }
                    if selected == .custom {
                        TextField("Name your habit", text: $customName)
                    }
                }
                
                Section("Your triggers") {
                    TextField("Semicolon-separated", text: $triggersText)
                        .textInputAutocapitalization(.never)
                        .font(.callout)
                }
                
                Section("Panic plan") {
                    TextEditor(text: $panicPlan).frame(minHeight: 100)
                }
                
                Section {
                    Button {
                        let triggers = triggersText
                            .split(separator: ";")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let config = HabitConfig(
                            type: selected,
                            customName: selected == .custom ? (customName.isEmpty ? "My Habit" : customName) : nil,
                            triggers: triggers,
                            panicPlan: panicPlan.isEmpty ? "Breathe + Cold water + Text friend" : panicPlan
                        )
                        store.completeOnboarding(habit: config)
                    } label: {
                        Text("Start")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Set up")
        }
    }
}
SWIFT

# --- Views/HomeView.swift ---
cat > "$APP_DIR/Views/HomeView.swift" <<'SWIFT'
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showFlow = false
    @State private var showSettings = false
    
    var habitName: String {
        let h = store.state.habit
        return h.type == .custom ? (h.customName ?? "My Habit") : h.type.display
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(habitName)")
                                .font(.title2).bold()
                            Text("Streak: \(store.state.streakDays) day\(store.state.streakDays == 1 ? "" : "s")")
                                .font(.headline)
                            Text("Successful urges: \(store.state.successfulUrges)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Panic Plan
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Panic plan")
                            .font(.headline)
                        Text(store.state.habit.panicPlan)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Triggers
                    if !store.state.habit.triggers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common triggers")
                                .font(.headline)
                            FlowLayout(items: store.state.habit.triggers) { t in
                                Text(t)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Big button
                    Button {
                        showFlow = true
                    } label: {
                        Text("I’m having an urge")
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Breaker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showFlow) {
                UrgeFlowView()
                    .presentationDetents([.medium, .large])
                    .environmentObject(store)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
        }
    }
}

/// tiny helper to lay out trigger chips
struct FlowLayout<Content: View, T: Hashable>: View {
    let items: [T]
    let content: (T) -> Content
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                self.generate(in: geo)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generate(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding([.vertical, .trailing], 6)
                    .alignmentGuide(.leading) { d in
                        if width + d.width > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last! {
                            width = 0
                        } else {
                            width += d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last! {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async { binding.wrappedValue = -geo.frame(in: .local).origin.y }
            return Color.clear
        }
    }
}
SWIFT

# --- Views/UrgeFlow/UrgeFlowView.swift ---
cat > "$APP_DIR/Views/UrgeFlow/UrgeFlowView.swift" <<'SWIFT'
import SwiftUI

enum UrgeStep: Int, CaseIterable {
    case delay, breathe, doTask, log
}

struct UrgeFlowView: View {
    @EnvironmentObject var store: HabitStore
    @State private var step: UrgeStep = .delay
    @State private var completed = Set<UrgeStep>()
    
    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $step) {
                DelayTimerView(onDone: { next(.breathe) })
                    .tag(UrgeStep.delay)
                BreathingView(onDone: { next(.doTask) })
                    .tag(UrgeStep.breathe)
                CopingTaskView(onDone: { next(.log) })
                    .tag(UrgeStep.doTask)
                LogOutcomeView(onSuccess: {
                    store.logSuccess()
                    dismiss()
                }, onRelapse: { trigger, notes in
                    store.logRelapse(trigger: trigger, notes: notes)
                    dismiss()
                })
                .tag(UrgeStep.log)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .padding()
        .presentationDragIndicator(.visible)
    }
    
    private func next(_ s: UrgeStep) {
        completed.insert(step)
        withAnimation { step = s }
    }
    private func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
SWIFT

# --- Views/UrgeFlow/DelayTimerView.swift ---
cat > "$APP_DIR/Views/UrgeFlow/DelayTimerView.swift" <<'SWIFT'
import SwiftUI

struct DelayTimerView: View {
    let onDone: () -> Void
    @State private var secondsRemaining: Int = 600
    @State private var running = false
    @Environment(\.scenePhase) private var phase
    @State private var lastBackgroundDate: Date?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Delay the urge (10 minutes)")
                .font(.title3).bold()
            Text("Urges rise and fall like waves. Let’s surf it.")
                .foregroundStyle(.secondary)
            
            Text(timeString(secondsRemaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            ProgressView(value: Double(600 - secondsRemaining), total: 600)
            
            HStack {
                Button(running ? "Pause" : "Start") {
                    running.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                if secondsRemaining < 600 {
                    Button("Skip") { onDone() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard running else { return }
            if secondsRemaining > 0 { secondsRemaining -= 1 }
            if secondsRemaining == 0 { onDone() }
        }
        .onChange(of: phase) { newPhase in
            if newPhase == .background { lastBackgroundDate = Date() }
            if newPhase == .active, let last = lastBackgroundDate, running {
                let delta = Int(Date().timeIntervalSince(last))
                secondsRemaining = max(secondsRemaining - delta, 0)
            }
        }
    }
    
    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
SWIFT

# --- Views/UrgeFlow/BreathingView.swift ---
cat > "$APP_DIR/Views/UrgeFlow/BreathingView.swift" <<'SWIFT'
import SwiftUI

struct BreathingView: View {
    let onDone: () -> Void
    @State private var phase: Double = 0
    @State private var step = 0
    private let script: [(String, Double)] = [("Inhale", 4), ("Hold", 7), ("Exhale", 8)]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("4–7–8 Breathing")
                .font(.title3).bold()
            Text(script[step].0)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(phase))
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: script[step].1), value: phase)
            }
            .frame(width: 180, height: 180)
            
            Button("Next") {
                advance()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { startStep() }
    }
    
    private func startStep() {
        phase = 0
        withAnimation(.linear(duration: script[step].1)) {
            phase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + script[step].1) {
            advance()
        }
    }
    
    private func advance() {
        if step < script.count - 1 {
            step += 1
            startStep()
        } else {
            onDone()
        }
    }
}
SWIFT

# --- Views/UrgeFlow/CopingTaskView.swift ---
cat > "$APP_DIR/Views/UrgeFlow/CopingTaskView.swift" <<'SWIFT'
import SwiftUI

struct CopingTaskView: View {
    let onDone: () -> Void
    @State private var task: String = CopingTaskView.randomTask()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick coping task")
                .font(.title3).bold()
            Text(task)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            HStack {
                Button("New idea") { task = Self.randomTask() }
                .buttonStyle(.bordered)
                Button("Done") { onDone() }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    static func randomTask() -> String {
        let options = [
            "Drink a full glass of cold water.",
            "Go outside for 3 minutes. Look far away.",
            "Text your accountability buddy: “Having an urge—say something encouraging.”",
            "10 push-ups or 20 bodyweight squats.",
            "Put phone in another room for 10 minutes.",
            "Box breathing: 4 in, 4 hold, 4 out, 4 hold (2 minutes).",
            "Write one sentence: Why do I want to quit?",
            "Chew gum or brush teeth.",
            "Open notes: list 3 triggers you noticed today.",
            "Take a brisk 2-minute walk."
        ]
        return options.randomElement()!
    }
}
SWIFT

# --- Views/LogOutcomeView.swift ---
cat > "$APP_DIR/Views/LogOutcomeView.swift" <<'SWIFT'
import SwiftUI

struct LogOutcomeView: View {
    var onSuccess: () -> Void
    var onRelapse: (_ trigger: String?, _ notes: String?) -> Void
    
    @EnvironmentObject var store: HabitStore
    @State private var outcome: Int = 0 // 0 success, 1 relapse
    @State private var trigger: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        Form {
            Section("Outcome") {
                Picker("Result", selection: $outcome) {
                    Text("I rode out the urge ✅").tag(0)
                    Text("I relapsed ❌").tag(1)
                }.pickerStyle(.segmented)
            }
            Section("What triggered it?") {
                TextField("Optional (e.g., stress, boredom…)", text: $trigger)
            }
            Section("Notes") {
                TextEditor(text: $notes).frame(minHeight: 100)
            }
            Section {
                Button("Save") {
                    if outcome == 0 { onSuccess() }
                    else { onRelapse(trigger.isEmpty ? nil : trigger, notes.isEmpty ? nil : notes) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Log outcome")
    }
}
SWIFT

# --- Views/SettingsView.swift ---
cat > "$APP_DIR/Views/SettingsView.swift" <<'SWIFT'
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
SWIFT

echo "✅ Files written. Next:"
echo "1) open \"$PROJ/BadHabitBreaker.xcodeproj\""
echo "2) If files don't appear, do: File → Add Files to \"BadHabitBreaker\"…"
echo "3) Run on a simulator."
