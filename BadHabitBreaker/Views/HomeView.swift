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
