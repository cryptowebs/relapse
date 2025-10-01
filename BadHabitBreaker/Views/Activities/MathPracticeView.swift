import SwiftUI

struct MathPracticeView: View {
    @State private var a = Int.random(in: 2...12)
    @State private var b = Int.random(in: 2...12)
    @State private var op: Op = [.mul, .sub, .add].randomElement()!
    @State private var input = ""
    @State private var score = 0
    
    enum Op: CaseIterable { case add, sub, mul }
    
    var body: some View {
        VStack(spacing: 14) {
            Text("Math practice").font(.headline)
            Text(problemText)
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
            HStack {
                TextField("=", text: $input).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                Button("OK") { check() }.buttonStyle(.borderedProminent)
            }
            Text("Score: \(score)").foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    private var problemText: String {
        switch op {
        case .add: return "\(a) + \(b)"
        case .sub: return "\(a) − \(b)"
        case .mul: return "\(a) × \(b)"
        }
    }
    private var correct: Int {
        switch op {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        }
    }
    private func check() {
        guard let val = Int(input.trimmingCharacters(in: .whitespaces)) else { return }
        if val == correct { score += 1 }
        newRound()
    }
    private func newRound() {
        a = Int.random(in: 2...12)
        b = Int.random(in: 2...12)
        op = [.mul,.sub,.add].randomElement()!
        input = ""
    }
}
