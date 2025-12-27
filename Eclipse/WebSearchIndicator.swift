//
//  WebSearchIndicator.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import SwiftUI

struct WebSearchIndicator: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var currentQuery: String = "Searching..."
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated globe icon with pulse
            ZStack {
                // Pulse ring
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                
                // Globe icon
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .frame(width: 20, height: 20)
            
            // Text
            Text("Searching the web")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular.tint(.blue.opacity(0.15)).interactive(), in: .capsule)
        .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
        .onAppear {
            // Slower, smoother rotation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // Gentler pulse animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.8
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.08, blue: 0.08)
            .ignoresSafeArea()
        
        WebSearchIndicator()
    }
}
