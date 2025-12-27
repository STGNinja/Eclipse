//
//  MusicAuthView.swift
//  Eclipse
//
//  Created by Antigravity on 12/21/25.
//

import SwiftUI
import MusicKit

struct MusicAuthView: View {
    var onSuccess: () -> Void
    @StateObject private var authManager = MusicAuthorizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dark Background
            Color(hex: "#121212").ignoresSafeArea()
            
            // Gradient Glow
            Circle()
                .fill(Color(hex: "#FC3C44").opacity(0.15))
                .blur(radius: 100)
                .frame(width: 400, height: 400)
                .offset(y: -100)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "#FC3C44").opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Text
                VStack(spacing: 16) {
                    Text("Connect Apple Music")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Unlock full playback, personalized recommendations, and seamless library integration directly within Eclipse.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        Task {
                            let authorized = await authManager.requestAuthorization()
                            if authorized {
                                HapticManager.shared.notification(.success)
                                onSuccess() // Dismiss self
                            } else {
                                HapticManager.shared.notification(.error)
                            }
                        }
                    } label: {
                        Text("Connect Account")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")], startPoint: .leading, endPoint: .trailing))
                            )
                            .shadow(color: Color(hex: "#FC3C44").opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        // onAppear removed to prevent premature dismissal
    }
}
