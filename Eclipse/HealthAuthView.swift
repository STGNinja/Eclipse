//
//  HealthAuthView.swift
//  Eclipse
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

struct HealthAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var isAnimating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var onSuccess: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Gradient Blobs
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -200)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 250, height: 250)
                    .offset(x: 100, y: 150)
                    .blur(radius: 60)
            }
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 30) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .opacity(0.5)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.top, 60)
                
                VStack(spacing: 16) {
                    Text("Connect Health")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Eclipse uses your health data to provide personalized wellness insights, helping you balance productivity with well-being.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 24) {
                    featureRow(icon: "figure.walk", title: "Activity Tracking", subtitle: "Steps and daily movement")
                    featureRow(icon: "bed.double.fill", title: "Sleep Analysis", subtitle: "Rest and recovery monitoring")
                    featureRow(icon: "heart.circle.fill", title: "Heart Health", subtitle: "Heart rate trends")
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        Task {
                            HapticManager.shared.impact(.medium)
                            do {
                                try await healthManager.requestAuthorization()
                                HapticManager.shared.notification(.success)
                                onSuccess()
                                dismiss()
                            } catch {
                                print("Health Auth Error: \(error)")
                                errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                    } label: {
                        Text("Allow Access")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .alert("Access Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Could not access Health data. Please verify permissions in iOS Settings.\nError: \(errorMessage)")
        }
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}
