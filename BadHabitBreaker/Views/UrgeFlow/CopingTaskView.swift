import SwiftUI

struct CopingTaskView: View {
    let onDone: () -> Void
    @State private var task: String = CopingTaskView.randomTask()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick coping task")
                .font(.title3).bold()
            Text(task)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            HStack {
                Button("New idea") { task = Self.randomTask() }
                .buttonStyle(.bordered)
                Button("Done") { onDone() }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    static func randomTask() -> String {
        let options = [
            "Drink a full glass of cold water.",
            "Go outside for 3 minutes. Look far away.",
            "Text your accountability buddy: “Having an urge—say something encouraging.”",
            "10 push-ups or 20 bodyweight squats.",
            "Put phone in another room for 10 minutes.",
            "Box breathing: 4 in, 4 hold, 4 out, 4 hold (2 minutes).",
            "Write one sentence: Why do I want to quit?",
            "Chew gum or brush teeth.",
            "Open notes: list 3 triggers you noticed today.",
            "Take a brisk 2-minute walk."
        ]
        return options.randomElement()!
    }
}
