import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showFlow = false
    @State private var showSettings = false
    
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
                                }
                                .font(.subheadline)
                            }
                            Spacer()
                        }
                    }
                    .glassCard()
                    
                    RiskMeterView(score: riskScore)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Plan for an urge", systemImage: "shield.lefthalf.filled")
                                .font(.headline)
                            Spacer()
                        }
                        Text(store.state.habit.panicPlan)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .glassCard()
                    
                    if !store.state.habit.triggers.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Common triggers", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                            FlowLayout(items: store.state.habit.triggers) { t in
                                Text(t)
                                    .font(.callout.weight(.medium))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(.thinMaterial, in: Capsule())
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.06)))
                            }
                        }
                        .glassCard()
                    }
                    
                    Button {
                        Haptics.lightTap()
                        showFlow = true
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
            .sheet(isPresented: $showFlow) {
                ZStack {
                    AppTheme.bgGradient.ignoresSafeArea()
                    UrgeFlowView()
                        .environmentObject(store)
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showSettings) {
                ZStack {
                    AppTheme.bgGradient.ignoresSafeArea()
                    SettingsView()
                        .environmentObject(store)
                }
            }
            .scrollIndicators(.hidden)
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
                        width += d.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
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
