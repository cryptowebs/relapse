import SwiftUI

struct PuzzleView: View {
    @State private var a = Int.random(in: 10...99)
    @State private var b = Int.random(in: 10...99)
    @State private var answer = ""
    @State private var streak = 0
    @State private var feedback = ""
    
    var body: some View {
        VStack(spacing: 14) {
            Text("Quick puzzle").font(.headline)
            Text("\(a) + \(b) = ?")
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
            HStack {
                TextField("Answer", text: $answer)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Check") { check() }.buttonStyle(.borderedProminent)
            }
            Text("Streak: \(streak)").foregroundStyle(.secondary)
            if !feedback.isEmpty {
                Text(feedback).font(.subheadline)
            }
        }
        .padding(.top, 4)
    }
    private func check() {
        guard let val = Int(answer.trimmingCharacters(in: .whitespaces)) else { feedback = "Enter a number."; return }
        if val == a + b {
            streak += 1; feedback = "Nice!"; newRound()
        } else {
            streak = 0; feedback = "Try again."
        }
    }
    private func newRound() {
        a = Int.random(in: 10...99)
        b = Int.random(in: 10...99)
        answer = ""
    }
}
