import SwiftUI

struct ArcReactorView: View {
    let size: CGFloat
    var animated: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium), lineWidth: 1)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            JarvisTheme.Colors.blue.opacity(0.4),
                            JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.subtle),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )

            // Core
            Circle()
                .fill(JarvisTheme.Colors.blue)
                .frame(width: size * 0.3, height: size * 0.3)
                .shadow(color: JarvisTheme.Colors.blue, radius: 4)

            // Rotating segments
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.prominent))
                    .frame(width: 2, height: size * 0.2)
                    .offset(y: -size * 0.3)
                    .rotationEffect(.degrees(Double(i) * 120 + rotation))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                startAnimation()
            }
        }
        .onChange(of: animated) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                rotation = 0
            }
        }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ArcReactorView(size: 32)
        ArcReactorView(size: 48, animated: true)
    }
    .padding()
    .background(JarvisTheme.Colors.dark)
}
