import SwiftUI

struct BuddySupportView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.openURL) private var openURL
    @State private var name = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Add buddy") {
                    TextField("Name", text: $name)
                    TextField("Phone (+1xxxxxxxxxx)", text: $phone)
                        .keyboardType(.phonePad)
                    Button {
                        guard !name.isEmpty, !phone.isEmpty else { return }
                        store.addBuddy(name: name, phone: phone)
                        name = ""; phone = ""
                        Haptics.success()
                    } label: { Label("Save buddy", systemImage: "person.crop.circle.badge.plus") }
                    .buttonStyle(.borderedProminent)
                }
                Section("My buddies") {
                    if store.state.buddies.isEmpty {
                        Text("Add 1–3 people you can contact during urges.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.state.buddies) { b in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(b.name).font(.headline)
                                    Text(b.phone).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { openURL(URL(string: "sms:\(b.phone)")!) } label: { Image(systemName: "text.bubble.fill") }
                                Button { openURL(URL(string: "tel:\(b.phone)")!) } label: { Image(systemName: "phone.fill") }
                                Button(role: .destructive) { store.removeBuddy(b.id) } label: { Image(systemName: "trash") }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bgGradient.ignoresSafeArea())
            .navigationTitle("Buddy support")
        }
    }
}
