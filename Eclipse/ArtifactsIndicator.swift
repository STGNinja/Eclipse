//
//  ArtifactsIndicator.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import SwiftUI

struct ArtifactsIndicator: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 10) {
            // Animated Icon with pulse effect
            ZStack {
                // Single subtle pulse ring
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                
                // Brain icon
                Image(systemName: "brain")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            .frame(width: 20, height: 20)
            
            // Text
            Text("Referencing Artifacts")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular.tint(.orange.opacity(0.15)).interactive(), in: .capsule)
        .shadow(color: .orange.opacity(0.2), radius: 8, x: 0, y: 4)
        .onAppear {
            // Slower, smoother rotation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            
            // Gentler pulse animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.8
            }
        }
    }
}

// Compact version for inline display
struct CompactArtifactsIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
            
            Text("Using artifacts")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(.orange.opacity(0.2)).interactive(), in: .capsule)
        .shadow(color: .orange.opacity(0.15), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.08, blue: 0.08)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ArtifactsIndicator()
                .padding()
            
            CompactArtifactsIndicator()
        }
    }
}
