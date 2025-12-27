//
//  LiquidInputBackground.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import SwiftUI

struct LiquidInputBackground: View {
    var isSpeaking: Bool
    
    var body: some View {
        ZStack {
            // Base layer
            Color.black.opacity(0.3)
            
            // Liquid Canvas
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    // Speed up animation when speaking
                    let speed = isSpeaking ? 120.0 : 40.0
                    let angle = now.remainder(dividingBy: 10) * speed
                    
                    // Threshhold filter for liquid effect
                    context.addFilter(.alphaThreshold(min: 0.5, color: isSpeaking ? .cyan : .blue.opacity(0.5)))
                    context.addFilter(.blur(radius: isSpeaking ? 12 : 8))
                    
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        
                        // Blob 1
                        let offset1 = CGPoint(
                            x: cos(angle * .pi / 180) * (isSpeaking ? 20 : 10),
                            y: sin(angle * .pi / 180) * (isSpeaking ? 10 : 5)
                        )
                        ctx.fill(
                            Circle().path(in: CGRect(x: center.x + offset1.x - 40, y: center.y + offset1.y - 40, width: 80, height: 80)),
                            with: .color(.blue.opacity(0.8))
                        )
                        
                        // Blob 2
                        let offset2 = CGPoint(
                            x: cos((angle + 120) * .pi / 180) * (isSpeaking ? 25 : 15),
                            y: sin((angle + 120) * .pi / 180) * (isSpeaking ? 15 : 8)
                        )
                        ctx.fill(
                            Circle().path(in: CGRect(x: center.x + offset2.x - 35, y: center.y + offset2.y - 35, width: 70, height: 70)),
                            with: .color(.cyan.opacity(0.7))
                        )
                        
                        // Blob 3
                        let offset3 = CGPoint(
                            x: cos((angle + 240) * .pi / 180) * (isSpeaking ? 20 : 10),
                            y: sin((angle + 240) * .pi / 180) * (isSpeaking ? 10 : 5)
                        )
                        ctx.fill(
                            Circle().path(in: CGRect(x: center.x + offset3.x - 30, y: center.y + offset3.y - 30, width: 60, height: 60)),
                            with: .color(.purple.opacity(0.6))
                        )
                    }
                }
            }
        }
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        LiquidInputBackground(isSpeaking: false)
            .frame(width: 300, height: 60)
        LiquidInputBackground(isSpeaking: true)
            .frame(width: 300, height: 60)
    }
    .padding()
    .background(Color.black)
}
