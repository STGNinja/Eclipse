//
//  AppearanceView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import SwiftUI
import PhotosUI

struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appearanceManager = AppearanceManager.shared
    @State private var selectedGradient: GradientStyle = .none
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            // Dark Theme Background
            Color(red: 0.08, green: 0.08, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 12) {
                        Text("Customize Your Experience")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                        
                        Text("Choose a gradient that reflects your style")
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    
                    // Preview Section
                    PreviewCard(gradient: selectedGradient)
                        .padding(.horizontal, 20)
                    
                    // Adaptive Background Toggle Removed

                    
                    // Custom Background Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Custom Background")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)
                            Spacer()
                            if appearanceManager.customBackgroundData != nil {
                                Button("Remove") {
                                    Task {
                                        try? await appearanceManager.setCustomBackground(nil)
                                    }
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    
                                    if let data = appearanceManager.customBackgroundData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appearanceManager.customBackgroundData == nil ? "Set Custom Background" : "Change Background")
                                        .font(.system(size: 16, weight: .medium, design: .serif))
                                        .foregroundStyle(.white)
                                    
                                    Text("Upload an image from your library")
                                        .font(.system(size: 13, design: .serif))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        }
                        
                        Text("Custom backgrounds are displayed when Adaptive Background is turned off.")
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.horizontal, 4)
                        
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    try? await appearanceManager.setCustomBackground(data)
                                    selectedItem = nil // Reset for next selection
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Gradient Options
                    VStack(spacing: 16) {
                        HStack {
                            Text("Gradient Styles")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(GradientStyle.allCases.count) styles")
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 24)
                        
                        // Capsule list of gradients
                        VStack(spacing: 12) {
                            ForEach(GradientStyle.allCases, id: \.self) { gradient in
                                GradientOption(
                                    gradient: gradient,
                                    isSelected: selectedGradient == gradient
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedGradient = gradient
                                        
                                        // Generate haptic feedback
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        
                                        // Save to Firebase
                                        Task {
                                            do {
                                                try await appearanceManager.saveAppearance(gradient)
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            } catch {
                                                print("Error saving appearance: \(error)")
                                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.08), for: .navigationBar)
        .onAppear {
            selectedGradient = appearanceManager.selectedGradient
        }
    }
}

// MARK: - Preview Card

struct PreviewCard: View {
    let gradient: GradientStyle
    
    var body: some View {
        ZStack {
            // Background with gradient
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08)
                
                // Custom Image Background if exists
                if let data = AppearanceManager.shared.customBackgroundData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(Color.black.opacity(0.4))
                } else {
                    // Gradient Overlay
                    if !gradient.colors.isEmpty {
                        ZStack {
                            ForEach(0..<gradient.colors.count, id: \.self) { index in
                                Circle()
                                    .fill(gradient.colors[index])
                                    .blur(radius: 60)
                                    .frame(width: 150, height: 150)
                                    .offset(
                                        x: CGFloat(index - 1) * 30,
                                        y: CGFloat(index - 1) * 20
                                    )
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Sample Chat Messages
            VStack(spacing: 14) {
                // AI Message
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.orange)
                        
                        Text("This is how your chat will look!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    
                    Spacer()
                }
                
                // User Message
                HStack {
                    Spacer()
                    
                    Text("Looks amazing!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Gradient Option

struct GradientOption: View {
    let gradient: GradientStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Gradient Preview Circle
                ZStack {
                    if gradient.colors.isEmpty {
                        // None/Default option
                        Circle()
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: gradient.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                    } else {
                        // Gradient option
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.08, green: 0.08, blue: 0.08))
                            
                            ForEach(0..<gradient.colors.count, id: \.self) { index in
                                Circle()
                                    .fill(gradient.colors[index])
                                    .blur(radius: 12)
                                    .frame(width: 32, height: 32)
                                    .offset(
                                        x: CGFloat(index - 1) * 6,
                                        y: CGFloat(index - 1) * 6
                                    )
                            }
                            
                            Image(systemName: gradient.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.orange : Color.clear,
                            lineWidth: isSelected ? 2.5 : 0
                        )
                        .frame(width: 48, height: 48)
                )
                
                // Name
                Text(gradient.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .serif))
                    .foregroundStyle(isSelected ? .orange : .white)
                
                Spacer()
                
                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .glassEffect(
                isSelected ? 
                    .regular.tint(.orange.opacity(0.1)).interactive() : 
                    .regular.interactive(), 
                in: .capsule
            )
            .shadow(
                color: isSelected ? .orange.opacity(0.2) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
