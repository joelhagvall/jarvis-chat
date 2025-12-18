import SwiftUI

struct GridBackground: View {
    var gridSize: CGFloat = 30
    var lineWidth: CGFloat = 0.5
    var lineOpacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(JarvisTheme.Colors.blue.opacity(lineOpacity)), lineWidth: lineWidth)
            }

            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(JarvisTheme.Colors.blue.opacity(lineOpacity)), lineWidth: lineWidth)
            }
        }
    }
}

#Preview {
    GridBackground()
        .frame(width: 300, height: 300)
        .background(JarvisTheme.Colors.dark)
}
