//
//  CanvaDesignCarousel.swift
//  Eclipse
//
//  Created by Antigravity on 12/19/25.
//

import SwiftUI

struct CanvaDesignCarousel: View {
    let designs: [CanvaDesignData]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(designs) { design in
                    CanvaDesignCard(design: design)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

struct CanvaDesignCard: View {
    let design: CanvaDesignData
    @Environment(\.openURL) private var openURL
    
    // Hash function to pick consistent colors for the same title
    private var gradientColors: [Color] {
        let hash = design.title.hash
        let colors: [[Color]] = [
            [.blue, .purple],
            [.orange, .pink],
            [.green, .blue],
            [.purple, .red],
            [.pink, .indigo],
            [.teal, .cyan]
        ]
        return colors[abs(hash) % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "Canvas" Area
            ZStack {
                // Background
                if let thumbUrl = design.thumbnailUrl, let url = URL(string: thumbUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: 220, height: 280) // Portrait ratio for posters/docs
            .clipped()
            .overlay(
                // Canva Tag
                HStack(spacing: 4) {
                    Image(systemName: "c.circle.fill")
                    Text("Canva")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(12)
                , alignment: .topTrailing
            )
            
            // Footer Action
            Button {
                if let url = URL(string: design.editUrl) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text("Open in Canva")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(.primary)
            }
        }
        .frame(width: 220)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // The "Visual Proxy" View
    private var placeholderView: some View {
        GeometricPattern(colors: gradientColors)
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    
                    // Design Title as "Art"
                    Text(design.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 20)
                        .padding(.horizontal, 16)
                    
                    // "Concept" Label
                    Text("TEMPLATE CONCEPT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                }
                , alignment: .bottomLeading
            )
    }
}

// Simple geometric background pattern
struct GeometricPattern: View {
    let colors: [Color]
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 300)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(.black.opacity(0.1))
                    .frame(width: 200)
                    .offset(x: 100, y: 100)
            }
        )
    }
}

#Preview {
    ZStack {
        Color.black
        CanvaDesignCarousel(designs: [
            CanvaDesignData(designId: "1", title: "Premium Car Wash Flyer", editUrl: "https://canva.com", viewUrl: "", thumbnailUrl: nil),
            CanvaDesignData(designId: "2", title: "Summer Sale Instagram Post", editUrl: "https://canva.com", viewUrl: "", thumbnailUrl: nil)
        ])
    }
}
