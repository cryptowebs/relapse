import SwiftUI

struct RiskMeterView: View {
    let score: Double // 0...1
    
    var color: Color {
        switch score {
        case ..<0.33: return AppTheme.positive
        case ..<0.66: return AppTheme.warning
        default: return AppTheme.danger
        }
    }
    
    var label: String {
        switch score {
        case ..<0.33: return "Low"
        case ..<0.66: return "Medium"
        default: return "High"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                Text("Risk right now")
                    .font(.headline)
                Spacer()
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }
            ProgressView(value: score)
                .tint(color)
                .shadow(color: color.opacity(0.35), radius: 12, y: 6)
            Text(hintText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
    
    private var hintText: String {
        if score >= 0.66 { return "High-risk window. Try a quick plan: delay 5m → breathe → text buddy." }
        if score >= 0.33 { return "Medium risk. A 2-minute breathing break helps a lot." }
        return "Looking good. Keep easy wins going."
    }
}
