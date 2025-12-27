//
//  WeatherCardView.swift
//  Eclipse
//
//  Created by Antigravity on 12/19/25.
//

import SwiftUI

struct WeatherCardView: View {
    let data: WeatherData
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Dynamic Background based on time of day
            LinearGradient(
                colors: data.isDaylight 
                    ? [Color(hex: "4A90E2"), Color(hex: "87CEEB")] // Day: Blue to Light Blue
                    : [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")], // Night: Dark Gradient
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    // Location/Title (Fixed for now, could be dynamic)
                    Text("Current Location")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                    
                    // Large Temperature
                    Text(data.temperature)
                        .font(.system(size: 52, weight: .light)) // Thin/Light weight like Apple Weather
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .minimumScaleFactor(0.5) // Prevent truncation for "Forecast" fallback
                    
                    // Condition Description
                    Text(data.condition)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .shadow(radius: 2)
                }
                .padding(.vertical, 20)
                .padding(.leading, 24)
                
                Spacer()
                
                // Weather Icon
                VStack {
                    Image(systemName: data.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding(.trailing, 24)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160) // "Long card" height
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 4) // Slight inset in chat
    }
}
