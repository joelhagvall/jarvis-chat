import SwiftUI

struct HexDivider: View {
    var body: some View {
        HStack(spacing: JarvisTheme.Spacing.xs) {
            gradientLine(leading: true)

            Image(systemName: "hexagon.fill")
                .font(.system(size: 6))
                .foregroundStyle(JarvisTheme.Colors.blue.opacity(0.4))

            gradientLine(leading: false)
        }
        .padding(.horizontal, JarvisTheme.Spacing.lg)
    }

    private func gradientLine(leading: Bool) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: leading
                        ? [Color.clear, JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium)]
                        : [JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Above")
        HexDivider()
        Text("Below")
    }
    .foregroundStyle(.white)
    .padding()
    .background(JarvisTheme.Colors.dark)
}
