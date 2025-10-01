import SwiftUI

struct MyUrgesView: View {
    @EnvironmentObject var store: HabitStore
    @State private var editing: UserUrge?
    
    var body: some View {
        NavigationStack {
            List {
                if store.state.myUrges.isEmpty {
                    Text("No urges yet. Add some from Discover.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.state.myUrges) { u in
                        Button {
                            editing = u
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(u.displayName).font(.headline)
                                    Text(summary(of: u)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                                Spacer()
                                Text("\(u.currentStreak)d").font(.caption).padding(6)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in
                        for i in idx { store.removeUrge(id: store.state.myUrges[i].id) }
                    }
                }
            }
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("My Urges")
            .sheet(item: $editing) { u in
                EditUrgeSheet(urge: u) { updated in store.updateUrge(updated) }
                    .environmentObject(store)
            }
        }
    }
    
    private func summary(of u: UserUrge) -> String {
        var bits: [String] = []
        if let wd = u.whatDoingNow, !wd.isEmpty { bits.append(wd) }
        if !u.whatWorks.isEmpty { bits.append("Works: " + u.whatWorks.joined(separator: ", ")) }
        if !u.whatDoesnt.isEmpty { bits.append("Doesn’t: " + u.whatDoesnt.joined(separator: ", ")) }
        if !u.temptations.isEmpty { bits.append("Temptations: " + u.temptations.joined(separator: ", ")) }
        return bits.joined(separator: " • ")
    }
}

private struct EditUrgeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: HabitStore
    var urge: UserUrge
    var onSave: (UserUrge) -> Void
    
    @State private var whatDoing = ""
    @State private var works = ""
    @State private var doesnt = ""
    @State private var temps = ""
    @State private var streak = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("\(urge.displayName)") {
                    TextField("What are you doing now?", text: $whatDoing)
                    TextField("What works (comma-separated)", text: $works)
                    TextField("What doesn't (comma-separated)", text: $doesnt)
                    TextField("What tempts you (comma-separated)", text: $temps)
                    Stepper("Current streak: \(streak) days", value: $streak, in: 0...999)
                }
                Section {
                    Button {
                        var u = urge
                        u.whatDoingNow = whatDoing.isEmpty ? nil : whatDoing
                        u.whatWorks = works.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty}
                        u.whatDoesnt = doesnt.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty}
                        u.temptations = temps.split(separator: ",").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty}
                        u.currentStreak = streak
                        onSave(u)
                        Haptics.success()
                        dismiss()
                    } label: { Label("Save", systemImage: "checkmark.circle.fill") }
                    .buttonStyle(.borderedProminent)
                }
                Section {
                    Button(role: .destructive) {
                        store.removeUrge(id: urge.id)
                        dismiss()
                    } label: { Label("Delete urge", systemImage: "trash") }
                }
            }
            .onAppear {
                whatDoing = urge.whatDoingNow ?? ""
                works = urge.whatWorks.joined(separator: ", ")
                doesnt = urge.whatDoesnt.joined(separator: ", ")
                temps = urge.temptations.joined(separator: ", ")
                streak = urge.currentStreak
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Edit")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
