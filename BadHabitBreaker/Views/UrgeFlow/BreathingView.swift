import SwiftUI

struct BreathingView: View {
    let onDone: () -> Void
    @State private var phase: Double = 0
    @State private var step = 0
    private let script: [(String, Double)] = [("Inhale", 4), ("Hold", 7), ("Exhale", 8)]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("4–7–8 Breathing")
                .font(.title3).bold()
            Text(script[step].0)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(phase))
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: script[step].1), value: phase)
            }
            .frame(width: 180, height: 180)
            
            Button("Next") {
                advance()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { startStep() }
    }
    
    private func startStep() {
        phase = 0
        withAnimation(.linear(duration: script[step].1)) {
            phase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + script[step].1) {
            advance()
        }
    }
    
    private func advance() {
        if step < script.count - 1 {
            step += 1
            startStep()
        } else {
            onDone()
        }
    }
}
