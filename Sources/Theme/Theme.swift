import SwiftUI

// MARK: - JARVIS Design System

enum JarvisTheme {
    // MARK: - Colors
    enum Colors {
        static let blue = Color(red: 0.0, green: 0.8, blue: 1.0)
        static let gold = Color(red: 1.0, green: 0.75, blue: 0.3)
        static let dark = Color(red: 0.02, green: 0.05, blue: 0.1)
        static let panel = Color(red: 0.05, green: 0.1, blue: 0.15)
        static let glow = Color(red: 0.0, green: 0.6, blue: 0.8)
    }

    // MARK: - Typography
    enum Typography {
        static func label(_ size: CGFloat = 10, tracking: CGFloat = 2) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }

        static func body(_ size: CGFloat = 14) -> Font {
            .system(size: size, design: .default)
        }

        static func mono(_ size: CGFloat = 13) -> Font {
            .system(size: size, design: .monospaced)
        }

        static func title(_ size: CGFloat = 14) -> Font {
            .system(size: size, weight: .light, design: .monospaced)
        }

        static func heading(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
    }

    // MARK: - Opacity Levels
    enum Opacity {
        static let subtle: Double = 0.1
        static let light: Double = 0.2
        static let medium: Double = 0.3
        static let strong: Double = 0.5
        static let prominent: Double = 0.6
        static let solid: Double = 0.7
    }
}

// MARK: - Color Extension (backwards compatibility)

extension Color {
    static let jarvisBlue = JarvisTheme.Colors.blue
    static let jarvisGold = JarvisTheme.Colors.gold
    static let jarvisDark = JarvisTheme.Colors.dark
    static let jarvisPanel = JarvisTheme.Colors.panel
    static let jarvisGlow = JarvisTheme.Colors.glow
}
