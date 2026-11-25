import SwiftUI

/// Texte d'une ligne pour un bouton de la télécommande : tronqué (…) tant que le bouton n'est pas sélectionné, il défile
/// doucement dans le bouton quand celui-ci prend le focus, pour pouvoir lire un titre trop long en entier.
struct TVMarqueeText: View {
    let text: String
    var font: Font = .body
    @Environment(\.isFocused) private var isFocused
    @State private var fullWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    init(_ text: String, font: Font = .body) {
        self.text = text
        self.font = font
    }

    private var overflow: CGFloat { max(fullWidth - boxWidth, 0) }
    private var scrolling: Bool { isFocused && overflow > 1 }

    var body: some View {
        ZStack(alignment: .leading) {
            if scrolling {
                Text(text).font(font).lineLimit(1).fixedSize().offset(x: offset)
            } else {
                Text(text).font(font).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .background(GeometryReader { box in Color.clear.preference(key: MarqueeBoxKey.self, value: box.size.width) })
        .background(
            Text(text).font(font).lineLimit(1).fixedSize().hidden()
                .background(GeometryReader { full in Color.clear.preference(key: MarqueeFullKey.self, value: full.size.width) })
        )
        .onPreferenceChange(MarqueeBoxKey.self) { boxWidth = $0 }
        .onPreferenceChange(MarqueeFullKey.self) { fullWidth = $0 }
        .task(id: scrolling) {
            offset = 0
            guard scrolling else { return }
            let distance = overflow + 6
            let duration = max(Double(distance) / 60, 1)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 800_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: duration)) { offset = -distance }
                try? await Task.sleep(nanoseconds: UInt64((duration + 1) * 1_000_000_000))
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { offset = 0 }
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
    }
}

private struct MarqueeBoxKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct MarqueeFullKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
