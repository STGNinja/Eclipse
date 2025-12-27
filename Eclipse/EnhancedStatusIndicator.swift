//
//  EnhancedStatusIndicator.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import SwiftUI

struct EnhancedStatusIndicator: View {
    var isConnected: Bool
    var isAISpeaking: Bool
    var isUserSpeaking: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            // Animated Status Orb
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)

                // Main orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [statusColor, statusColor.opacity(0.7)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 10, height: 10)
                    .shadow(color: statusColor.opacity(0.8), radius: 8)
                    .shadow(color: statusColor.opacity(0.4), radius: 16)

                // Rotating arc for speaking states
                if isAISpeaking || isUserSpeaking {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(statusColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(rotation))
                }
            }

            // Status Text
            Text(statusText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive())
        .onAppear {
            startAnimations()
        }
        .onChange(of: isAISpeaking) { _, _ in
            startAnimations()
        }
        .onChange(of: isUserSpeaking) { _, _ in
            startAnimations()
        }
    }

    private var statusColor: Color {
        if isAISpeaking {
            return .purple
        } else if isUserSpeaking {
            return .blue
        } else if isConnected {
            return .green
        } else {
            return .orange
        }
    }

    private var statusText: String {
        if isAISpeaking {
            return "Speaking"
        } else if isUserSpeaking {
            return "Listening"
        } else if isConnected {
            return "Live"
        } else {
            return "Connecting"
        }
    }

    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.4
        }

        // Rotation for speaking states
        if isAISpeaking || isUserSpeaking {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                rotation = 0
            }
        }
    }
}
