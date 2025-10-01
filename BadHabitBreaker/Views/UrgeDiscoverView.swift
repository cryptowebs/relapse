import SwiftUI

struct UrgeDiscoverView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showSheet = false
    @State private var selected: HabitType = .nicotine
    @State private var customName: String = ""
    
    let cols = [GridItem(.flexible()), GridItem(.flexible())]
    let types: [HabitType] = [.nicotine, .alcohol, .sugar, .doomscrolling, .gambling, .porn, .custom]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 16) {
                    ForEach(types) { t in
                        Button {
                            selected = t
                            customName = ""
                            showSheet = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: icon(for: t))
                                    .font(.system(size: 44))
                                Text(t.display)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Discover")
            .sheet(isPresented: $showSheet) {
                AddUrgeSheet(selected: $selected, customName: $customName)
                    .environmentObject(store)
            }
        }
    }
    
    private func icon(for t: HabitType) -> String {
        switch t {
        case .nicotine: return "smoke.fill"
        case .alcohol: return "wineglass.fill"
        case .sugar: return "cube.fill"
        case .doomscrolling: return "iphone.gen3.radiowaves.left.and.right"
        case .gambling: return "suit.club.fill"
        case .porn: return "eye.fill"
        case .custom: return "plus.app.fill"
        }
    }
}

private struct AddUrgeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: HabitStore
    @Binding var selected: HabitType
    @Binding var customName: String
    @State private var whatDoing = ""
    @State private var works = ""
    @State private var doesnt = ""
    @State private var temps = ""
    @State private var streak = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Urge") {
                    Picker("Type", selection: $selected) {
                        ForEach(HabitType.allCases) { t in Text(t.display).tag(t) }
                    }
                    if selected == .custom {
                        TextField("Custom name", text: $customName)
                    }
                }
                Section("Your experience") {
                    TextField("What are you doing now?", text: $whatDoing)
                    TextField("What works (comma-separated)", text: $works)
                    TextField("What doesn't (comma-separated)", text: $doesnt)
                    TextField("What tempts you (comma-separated)", text: $temps)
                    Stepper("Current streak: \(streak) days", value: $streak, in: 0...999)
                }
                Section {
                    Button {
                        let u = UserUrge(
                            type: selected,
                            customName: selected == .custom ? (customName.isEmpty ? "Custom" : customName) : nil,
                            whatDoingNow: whatDoing.isEmpty ? nil : whatDoing,
                            whatWorks: works.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty},
                            whatDoesnt: doesnt.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty},
                            temptations: temps.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty},
                            currentStreak: streak,
                            lastRelapseDate: nil,
                            createdAt: Date()
                        )
                        store.addUrge(u)
                        Haptics.success()
                        dismiss()
                    } label: { Label("Add to My Urges", systemImage: "plus.circle.fill") }
                    .buttonStyle(.borderedProminent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Add urge")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
