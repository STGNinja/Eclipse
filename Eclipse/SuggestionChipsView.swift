//
//  SuggestionChipsView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/21/25.
//

import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        HapticManager.shared.impact(.light)
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1)
                            )
                    }
                    .frame(height: 34)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SuggestionChipsView(suggestions: ["Tell me more", "Create a playlist", "Show me the map"]) { _ in }
    }
}
