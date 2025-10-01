import SwiftUI

struct UrgeCountdownView: View {
    @ObservedObject var session: UrgeSession
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Do this for 10 minutes")
                    .font(.headline)
                Spacer()
                Text(timeString(session.remaining))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            ProgressView(value: Double(session.duration - session.remaining), total: Double(session.duration))
                .tint(.white)
        }
        .onChange(of: session.remaining) { _, newVal in
            if newVal == 0 { onFinish() }
        }
    }
    
    private func timeString(_ s: Int) -> String {
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
