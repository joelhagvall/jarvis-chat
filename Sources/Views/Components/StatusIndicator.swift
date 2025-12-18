import SwiftUI

struct StatusIndicator: View {
    let text: String
    let color: Color
    @State private var opacity: Double = 0.5

    var body: some View {
        HStack(spacing: JarvisTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                        opacity = 1.0
                    }
                }

            Text(text)
                .font(JarvisTheme.Typography.label(11))
                .foregroundStyle(color)
                .tracking(2)
        }
        .jarvisCapsule(color: color, filled: true)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusIndicator(text: "ANALYZING", color: JarvisTheme.Colors.gold)
        StatusIndicator(text: "PROCESSING", color: JarvisTheme.Colors.blue)
    }
    .padding()
    .background(JarvisTheme.Colors.dark)
}
