//
//  TalkingEclipseDot.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import SwiftUI

struct TalkingEclipseDot: View {
    let isWaiting: Bool
    let isSpeaking: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var ringScale1: CGFloat = 0.8
    @State private var ringScale2: CGFloat = 0.8
    @State private var ringScale3: CGFloat = 0.8
    @State private var ringOpacity1: Double = 0.0
    @State private var ringOpacity2: Double = 0.0
    @State private var ringOpacity3: Double = 0.0
    
    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            ZStack {
                // Animated rings (only when speaking)
                if isSpeaking {
                    // Ring 1 - Outermost
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale1)
                        .opacity(ringOpacity1)
                    
                    // Ring 2 - Middle
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale2)
                        .opacity(ringOpacity2)
                    
                    // Ring 3 - Innermost
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale3)
                        .opacity(ringOpacity3)
                }
                
                // Main Eclipse dot with glassmorphism
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                        )
                    
                    // Eclipse logo or icon
                    if let uiImage = UIImage(named: "betterlunr.PNG") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                    } else {
                        Image(systemName: "moon.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    // Loading indicator overlay
                    if isWaiting {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isWaiting)
                    }
                }
                .scaleEffect(pulseScale)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isSpeaking) { _, newValue in
            if newValue {
                startSpeakingAnimation()
            } else {
                stopSpeakingAnimation()
            }
        }
    }
    
    private func startAnimations() {
        // Gentle breathing pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
    
    private func startSpeakingAnimation() {
        // Ring 1 animation
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            ringScale1 = 1.5
            ringOpacity1 = 0.0
        }
        ringOpacity1 = 0.6
        
        // Ring 2 animation (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                ringScale2 = 1.5
                ringOpacity2 = 0.0
            }
            ringOpacity2 = 0.6
        }
        
        // Ring 3 animation (delayed more)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                ringScale3 = 1.5
                ringOpacity3 = 0.0
            }
            ringOpacity3 = 0.6
        }
    }
    
    private func stopSpeakingAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            ringScale1 = 0.8
            ringScale2 = 0.8
            ringScale3 = 0.8
            ringOpacity1 = 0.0
            ringOpacity2 = 0.0
            ringOpacity3 = 0.0
        }
    }
}

#Preview {
    TalkingEclipseDot(isWaiting: false, isSpeaking: true)
}
