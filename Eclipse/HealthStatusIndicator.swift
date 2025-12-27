//
//  HealthStatusIndicator.swift
//  Eclipse
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

struct HealthStatusIndicator: View {
    @State private var isSpinning = false
    
    var body: some View {
        ZStack {
            // Heart Outline
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 0)
                .rotation3DEffect(
                    .degrees(isSpinning ? 360 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: isSpinning
                )
            
            // "EKG" Pulse Line (Optional - abstract representation)
            // Keeping it clean with just the spinning heart for now as requested.
        }
        .onAppear {
            isSpinning = true
        }
    }
}

#Preview {
    ZStack {
        Color.black
        HealthStatusIndicator()
    }
}
