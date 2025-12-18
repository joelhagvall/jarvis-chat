import SwiftUI

/// Reusable status indicator with colored circle and text
struct StatusBadge: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    var activeColor: Color = .green
    var inactiveColor: Color = Color.red.opacity(0.7)

    var body: some View {
        HStack {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 8, height: 8)
            Text(isActive ? activeText : inactiveText)
                .font(JarvisTheme.Typography.mono(11))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.prominent))
            Spacer()
        }
    }
}

/// Badge for displaying tool names in a flow layout
struct ToolBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(JarvisTheme.Typography.mono(10))
            .foregroundStyle(JarvisTheme.Colors.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(JarvisTheme.Colors.blue.opacity(0.15))
            )
    }
}
