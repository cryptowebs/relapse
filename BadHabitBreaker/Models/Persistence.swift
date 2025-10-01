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
