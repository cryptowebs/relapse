import Foundation
import Combine

@MainActor
final class UrgeSession: ObservableObject {
    @Published var duration: Int = 600
    @Published var remaining: Int = 600
    @Published var running: Bool = false
    
    private var timerCancellable: AnyCancellable?
    private var lastBackgroundDate: Date?
    
    init(minutes: Int = 10) {
        duration = minutes*60
        remaining = duration
    }
    
    func start() {
        if remaining <= 0 { remaining = duration }
        running = true
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.running else { return }
                if self.remaining > 0 { self.remaining -= 1 }
                if self.remaining == 0 { self.running = false }
            }
    }
    func pause() { running = false }
    func reset() { running = false; remaining = duration }
    
    // background catch-up
    func wentBackground() { lastBackgroundDate = Date() }
    func becameActive() {
        guard running, let last = lastBackgroundDate else { return }
        let delta = Int(Date().timeIntervalSince(last))
        remaining = max(remaining - delta, 0)
        if remaining == 0 { running = false }
        lastBackgroundDate = nil
    }
}
