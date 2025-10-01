import SwiftUI

struct UrgeFlowView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.scenePhase) private var phase
    @StateObject private var session = UrgeSession(minutes: 10)
    @State private var picked: UrgeActivity? = nil
    @State private var showOutcome = false
    @State private var showFeedback = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Sticky header timer
            UrgeCountdownView(session: session) {
                // timer finished -> go to outcome
                showOutcome = true
            }
            
            // Activity area
            Group {
                if let p = picked {
                    activityView(for: p)
                } else {
                    ActivityPickerView { a in
                        picked = a
                        Haptics.lightTap()
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            // Outcome / Feedback sheets
            .sheet(isPresented: $showOutcome) {
                NavigationStack {
                    LogOutcomeView(onSuccess: {
                        store.logSuccess()
                        Haptics.success()
                        showOutcome = false
                        showFeedback = true
                    }, onRelapse: { trigger, notes in
                        store.logRelapse(trigger: trigger, notes: notes)
                        Haptics.warning()
                        showOutcome = false
                        showFeedback = true
                    })
                    .environmentObject(store)
                }
            }
            .sheet(isPresented: $showFeedback) {
                UrgeFeedbackSheet {
                    showFeedback = false
                }
                .environmentObject(store)
            }
        }
        .padding()
        .onAppear {
            session.start() // auto-start
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .background { session.wentBackground() }
            if newPhase == .active { session.becameActive() }
        }
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func activityView(for a: UrgeActivity) -> some View {
        switch a {
        case .game:
            MiniGameView().environmentObject(store)
        case .puzzle:
            PuzzleView()
        case .zen:
            ZenSoundsView()
        case .math:
            MathPracticeView()
        case .buddy:
            AIBuddyView()
        }
    }
}

private struct UrgeFeedbackSheet: View {
    @EnvironmentObject var store: HabitStore
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Text("How did that go?").font(.title3.bold())
            HStack(spacing: 12) {
                Button {
                    store.recordSOSFeedback(helped: true)
                    onDone()
                } label: {
                    Label("This helped me", systemImage: "hand.thumbsup.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    store.recordSOSFeedback(helped: false)
                    onDone()
                } label: {
                    Label("Still have urge", systemImage: "hand.thumbsdown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            VStack(spacing: 6) {
                Text("Wins so far: \(store.state.sosFeedback.helpedCount)")
                Text("Still-urge: \(store.state.sosFeedback.stillUrgeCount)")
                    .foregroundStyle(.secondary)
            }.font(.footnote)
        }
        .padding()
    }
}
