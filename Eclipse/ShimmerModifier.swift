import SwiftUI

struct ShimmerContainer<Content: View>: View {
    let content: Content
    @State private var phase: CGFloat = -200

    var body: some View {
        content
            .overlay(gradientView)
    }
    
    private var gradientView: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "#8B5CF6").opacity(0.3), // Purple
                    Color.white.opacity(0.8),
                    Color(hex: "#A78BFA").opacity(0.3), // Light purple
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 200)
            .offset(x: phase)
            .onAppear {
                withAnimation(
                    .linear(duration: 2.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = geometry.size.width + 200
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func shimmer() -> some View {
        ShimmerContainer(content: self)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "#8B5CF6"), // Purple
                        Color.white,
                        Color(hex: "#A78BFA") // Light purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
