import SwiftUI

struct AIBuddyView: View {
    @State private var input: String = ""
    @State private var messages: [Msg] = AIBuddyView.initialMessages
    
    struct Msg: Identifiable {
        let id = UUID()
        let sender: Sender
        let text: String
    }
    enum Sender { case me, bot }
    
    static let initialMessages: [Msg] = [
        Msg(sender: .bot, text: "I’m here. What’s the urge like right now? 0–10?")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { m in
                        MessageBubble(message: m)
                    }
                }
                .padding(.vertical, 4)
            }
            HStack {
                TextField("Type a few words…", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { send() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 6)
    }
    
    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(Msg(sender: .me, text: trimmed))
        input = ""
        
        let reply = coachReply(for: trimmed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            messages.append(Msg(sender: .bot, text: reply))
        }
    }
    
    private func coachReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("10") || lower.contains("9") {
            return "That’s intense. Try 4–7–8 breathing for 3 cycles. I’ll count with you. This will pass."
        }
        if lower.contains("angry") || lower.contains("anger") {
            return "Anger is a strong trigger. Step away for 2 minutes—cold water or a quick walk can reset the body."
        }
        if lower.contains("bored") || lower.contains("boring") {
            return "Boredom loves autopilot. Pick the tiniest task: 10 squats or one puzzle. I’ll celebrate the win with you."
        }
        if lower.contains("tired") || lower.contains("sleep") {
            return "When tired, urges spike. Try a 90-second eyes-closed breathing break, then we reassess."
        }
        if lower.contains("stress") || lower.contains("stressed") {
            return "Stress makes urges louder. Box-breathing: 4 in • 4 hold • 4 out • 4 hold, for 2 minutes."
        }
        return "I hear you. Label where you feel the urge, breathe slowly once, then choose a 2-minute action from the list above."
    }
}

private struct MessageBubble: View {
    let message: AIBuddyView.Msg
    var isMe: Bool { message.sender == .me }
    
    var body: some View {
        HStack {
            if !isMe { Spacer(minLength: 0) }
            Text(message.text)
                .padding(10)
                // Base material background (Material type)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                // Conditional overlay color (Color type), avoids Color/Material ternary
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isMe ? 0.12 : 0.0))
                )
                .frame(maxWidth: 280, alignment: .leading)
            if isMe { Spacer(minLength: 0) }
        }
    }
}
