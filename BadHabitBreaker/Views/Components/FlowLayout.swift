import SwiftUI
public struct FlowLayout<Content: View, T: Hashable>: View {
    let items: [T]; let content: (T)->Content
    @State private var totalHeight: CGFloat = .zero
    public init(items: [T], @ViewBuilder content: @escaping (T)->Content) { self.items = items; self.content = content }
    public var body: some View {
        VStack { GeometryReader { geo in self.generate(in: geo) } }.frame(height: totalHeight)
    }
    private func generate(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero; var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item).padding([.vertical,.trailing],6)
                    .alignmentGuide(.leading) { d in
                        if width + d.width > g.size.width { width = 0; height -= d.height }
                        let result = width; width += d.width; return result
                    }
                    .alignmentGuide(.top) { _ in height }
            }
        }.background(GeometryReader { geo -> Color in
            DispatchQueue.main.async { totalHeight = -geo.frame(in: .local).origin.y }
            return .clear
        })
    }
}
