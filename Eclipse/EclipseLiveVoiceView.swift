//
//  EclipseLiveVoiceView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import SwiftUI

struct EclipseLiveVoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voicePreferences = VoicePreferencesManager.shared
    @State private var selectedVoice: GeminiVoice
    
    init() {
        _selectedVoice = State(initialValue: VoicePreferencesManager.shared.selectedVoice)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.11)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Description
                    Text("Choose the voice for Eclipse Live conversations. Your preference is saved to your account.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // Voice Options
                    VStack(spacing: 12) {
                        ForEach(GeminiVoice.allCases) { voice in
                            VoiceOptionCard(
                                voice: voice,
                                isSelected: selectedVoice == voice,
                                action: {
                                    HapticManager.shared.impact(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedVoice = voice
                                        voicePreferences.saveVoicePreference(voice)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Eclipse Live Voice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Voice Option Card
struct VoiceOptionCard: View {
    let voice: GeminiVoice
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: voice.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? .purple : .white.opacity(0.6))
                }
                
                // Voice Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text(voice.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.purple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
        .buttonStyle(.plain)
    }
}
