import SwiftUI

/// Central visual identity for SolarScope: a dark, space-inspired palette with
/// restrained accent colours.
enum Theme {
    static let background = Color(red: 0.02, green: 0.04, blue: 0.09)
    static let surface = Color(red: 0.07, green: 0.10, blue: 0.17)
    static let surfaceRaised = Color(red: 0.11, green: 0.15, blue: 0.23)
    static let accent = Color(red: 1.00, green: 0.76, blue: 0.29)
    static let orbital = Color(red: 0.36, green: 0.74, blue: 0.98)
    static let hairline = Color.white.opacity(0.08)
    static let cornerRadius: CGFloat = 18
}

/// Shared spacing and sizing constants.
enum Layout {
    static let spacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 26
    /// Keeps text and cards readable on wide iPad screens.
    static let contentWidth: CGFloat = 760
}

extension View {
    /// Standard raised card surface used across the app.
    func cardBackground(_ fill: Color = Theme.surface) -> some View {
        background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    /// Full-bleed app background.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Caps content width and centres it so layouts stay comfortable on iPad.
    ///
    /// The outer infinite frame keeps the enclosing scroll view (and any
    /// background attached to it) at full width, while the inner frame keeps
    /// the actual content readable.
    func constrainedWidth() -> some View {
        frame(maxWidth: Layout.contentWidth)
            .frame(maxWidth: .infinity)
    }
}
