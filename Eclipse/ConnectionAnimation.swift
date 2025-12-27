//
//  ConnectionAnimation.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import SwiftUI

struct ConnectionAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Concentric rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale + Double(index) * 0.3)
                    .opacity(opacity - Double(index) * 0.2)
                    .rotationEffect(.degrees(rotation + Double(index) * 120))
            }

            // Center glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .purple.opacity(0.8),
                            .blue.opacity(0.4),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(scale * 0.8)
                .blur(radius: 20)

            // Success checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.2
            }

            withAnimation(.linear(duration: 1.2).repeatCount(1, autoreverses: false)) {
                rotation = 360
            }

            // Fade out and dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    scale = 1.5
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }
        }
    }
}

struct ConnectingAnimation: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Spinning loader
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .trim(from: 0, to: 0.6)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.8), .blue.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60 + CGFloat(index) * 20, height: 60 + CGFloat(index) * 20)
                            .rotationEffect(.degrees(rotation + Double(index) * 120))
                    }
                }
                .scaleEffect(scale)

                Text("Connecting to Eclipse")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}
