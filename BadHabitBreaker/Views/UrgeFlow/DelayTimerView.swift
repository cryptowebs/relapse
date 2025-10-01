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
                .contentTransition(.numericText())
            
            ProgressView(value: Double(600 - secondsRemaining), total: 600)
                .tint(.white)
            
            HStack {
                Button(running ? "Pause" : "Start") {
                    running.toggle()
                    Haptics.lightTap()
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
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                if secondsRemaining % 60 == 0 { Haptics.lightTap() }
            }
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
