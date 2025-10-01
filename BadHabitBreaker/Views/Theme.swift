import SwiftUI

// Central tokens for a consistent dark look
enum AppTheme {
    static let bgGradient = LinearGradient(
        colors: [
            Color(hue: 0.66, saturation: 0.18, brightness: 0.10),
            Color(hue: 0.70, saturation: 0.32, brightness: 0.12),
            Color(hue: 0.78, saturation: 0.38, brightness: 0.16)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accent = Color(.systemTeal)
    static let positive = Color.green
    static let warning = Color.orange
    static let danger  = Color.red
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.06))
            )
    }
}
extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.6 : 1.0), in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
