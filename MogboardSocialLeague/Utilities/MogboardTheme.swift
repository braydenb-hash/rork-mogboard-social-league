import SwiftUI

enum MogboardTheme {
    static let background = Color(red: 0, green: 0, blue: 0)
    static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let cardBorder = Color(red: 0.14, green: 0.14, blue: 0.14)
    static let accent = Color(red: 0.75, green: 1.0, blue: 0.0)
    static let mutedText = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let surfaceElevated = Color(red: 0.1, green: 0.1, blue: 0.1)

    static let cardCornerRadius: CGFloat = 6
    static let cardBorderWidth: CGFloat = 1
    static let cardShadowOffset: CGFloat = 3

    static let mono: Font.Design = .monospaced
}

struct GlowBorder: ViewModifier {
    let color: Color
    let radius: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glowBorder(_ color: Color, radius: CGFloat = 6, cornerRadius: CGFloat = MogboardTheme.cardCornerRadius) -> some View {
        modifier(GlowBorder(color: color, radius: radius, cornerRadius: cornerRadius))
    }
}
