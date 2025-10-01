import SwiftUI

struct ZenSoundsView: View {
    @State private var phase: Double = 0
    var body: some View {
        VStack(spacing: 12) {
            Text("Sit in silence").font(.headline)
            Text("Follow the dot to breathe.").foregroundStyle(.secondary)
            Circle()
                .stroke(lineWidth: 10).opacity(0.2)
                .overlay(
                    Circle()
                        .trim(from: 0, to: phase)
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: phase)
                )
                .frame(width: 140, height: 140)
                .onAppear { phase = 1 }
        }
        .padding(.top, 8)
    }
}
