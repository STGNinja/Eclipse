//
//  HealthWidgetView.swift
//  Eclipse
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

struct HealthWidgetView: View {
    let type: HealthWidgetType
    let value: String
    let unit: String
    
    enum HealthWidgetType: String {
        case steps = "steps"
        case sleep = "sleep"
        case heartRate = "heart_rate"
        case activeEnergy = "active_energy"
        case unknown
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .sleep: return "bed.double.fill"
            case .heartRate: return "heart.fill"
            case .activeEnergy: return "flame.fill"
            case .unknown: return "star.fill"
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .steps: return [.orange, .yellow]
            case .sleep: return [Color(hex: "00C6FF"), Color(hex: "0072FF")] // Deep Sky Blue
            case .heartRate: return [.red, .pink]
            case .activeEnergy: return [Color(hex: "FF0099"), Color(hex: "493240")]
            case .unknown: return [.gray, .white]
            }
        }
        
        var title: String {
            switch self {
            case .steps: return "Steps Today"
            case .sleep: return "Sleep Duration"
            case .heartRate: return "Heart Rate"
            case .activeEnergy: return "Active Energy"
            case .unknown: return "Health Data"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon Circle with Gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: type.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.2)
                    )
                    .frame(width: 56, height: 56)
                
                // Overlay spinning heart for heart rate, strictly static icon otherwise
                if type == .heartRate {
                     HealthStatusIndicator()
                } else {
                    Image(systemName: type.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: type.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: type.gradientColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                    
                    Text(unit)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Subtle "Sparkle" or decoration
             Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: 10)
        }
        .padding(20)
        .background(
            ZStack {
                Color.black.opacity(0.4)
                
                // Subtle gradient background based on type
                LinearGradient(
                    colors: [type.gradientColors.first!.opacity(0.15), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .frame(maxWidth: 320)
    }
}
