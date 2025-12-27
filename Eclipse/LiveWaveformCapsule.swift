//
//  LiveWaveformCapsule.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import SwiftUI

struct LiveWaveformCapsule: View {
    @ObservedObject var liveService = GoogleLiveService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated Waveform Bars
            HStack(spacing: 3) {
                ForEach(0..<4) { index in
                    WaveformBar(level: liveService.audioLevel, index: index)
                }
            }
            
            // Status Text
            Text(liveService.isAISpeaking ? "Speaking..." : "Listening...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .frame(width: 160) // Fixed width for stability
    }
}

struct WaveformBar: View {
    let level: Float
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 3, height: heightForLevel(level, index: index))
            // Smooth animation for height changes
            .animation(.easeInOut(duration: 0.1), value: level)
    }
    
    private func heightForLevel(_ level: Float, index: Int) -> CGFloat {
        // Base height
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 16
        
        // Randomize/stagger effect based on index to make it look like a wave
        // We use the single 'level' input but modulate it per bar
        let visualLevel = CGFloat(level)
        
        // Simple distinct multiplier for each bar to create "randomness"
        let multiplier: CGFloat
        switch index {
        case 0: multiplier = 0.6
        case 1: multiplier = 1.0
        case 2: multiplier = 0.8
        case 3: multiplier = 0.5
        default: multiplier = 0.7
        }
        
        let dynamicHeight = visualLevel * 20 * multiplier
        
        return min(max(minHeight, minHeight + dynamicHeight), maxHeight)
    }
}

#Preview {
    ZStack {
        Color.black
        LiveWaveformCapsule()
    }
}
