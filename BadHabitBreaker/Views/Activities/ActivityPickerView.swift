import SwiftUI

enum UrgeActivity: String, CaseIterable, Identifiable {
    case game, puzzle, zen, math, buddy
    var id: String { rawValue }
    var title: String {
        switch self {
        case .game:   return "Beat your high score"
        case .puzzle: return "Solve a puzzle"
        case .zen:    return "Sit in silence"
        case .math:   return "Practice math"
        case .buddy:  return "AI buddy support"
        }
    }
    var icon: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .puzzle: return "puzzlepiece.extension.fill"
        case .zen: return "leaf.fill"
        case .math: return "sum"
        case .buddy: return "message.fill"
        }
    }
}

struct ActivityPickerView: View {
    let onPick: (UrgeActivity) -> Void
    let cols = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(UrgeActivity.allCases) { a in
                Button {
                    onPick(a)
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: a.icon).font(.system(size: 36))
                        Text(a.title).font(.subheadline).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
