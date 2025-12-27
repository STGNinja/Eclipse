import SwiftUI

struct ThinkingIndicator: View {
    @State private var isAnimating = false
    @State private var currentTextIndex = 0
    @State private var shimmerOffset: CGFloat = -1.5
    
    private let thinkingTexts = [
        "Processing your request",
        "Understanding context",
        "Analyzing conversation",
        "Formulating response",
        "Thinking deeply",
        "Connecting the dots"
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated orbs
            HStack(spacing: 4) {
                // Orb 1
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Orb 2
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .cyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2),
                        value: isAnimating
                    )
                
                // Orb 3
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.8), .teal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4),
                        value: isAnimating
                    )
            }
            
            // Rotating status text
            Text(thinkingTexts[currentTextIndex])
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.8))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .id(currentTextIndex)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            ZStack {
                // Base background
                Capsule()
                    .fill(.white.opacity(0.1))
                
                // Shimmer effect
                LinearGradient(
                    colors: [
                        .white.opacity(0),
                        .white.opacity(0.1),
                        .white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset * 200)
                .clipShape(Capsule())
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
        }
        .onAppear {
            isAnimating = true
            
            // Shimmer animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
            
            // Text rotation timer
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentTextIndex = (currentTextIndex + 1) % thinkingTexts.count
                }
            }
        }
    }
}
