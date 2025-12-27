//
//  InteractiveImageEditorView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct InteractiveImageEditorView: View {
    @State private var currentImage: UIImage
    @State private var adjustmentValue: Double
    @State private var isProcessing = false
    @State private var showingAppliedToast = false
    
    let originalImage: UIImage
    let adjustmentType: AdjustmentType
    let onApply: (UIImage) -> Void
    let onCancel: () -> Void
    
    init(image: UIImage, adjustmentType: AdjustmentType, initialValue: Double = 0, onApply: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self._currentImage = State(initialValue: image)
        self.originalImage = image
        self.adjustmentType = adjustmentType
        self._adjustmentValue = State(initialValue: initialValue)
        self.onApply = onApply
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Preview with Glass Container
            ZStack {
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Processing overlay
                if isProcessing {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Controls Section
            VStack(spacing: 16) {
                // Adjustment Label
                HStack {
                    Image(systemName: iconForType(adjustmentType))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                    
                    Text(adjustmentType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(formattedValue)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular, in: .capsule)
                }
                .padding(.horizontal, 20)
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: $adjustmentValue, in: adjustmentType.range)
                        .tint(.orange)
                        .onChange(of: adjustmentValue) { _, newValue in
                            updateImage(value: newValue)
                        }
                    
                    // Range indicators
                    HStack {
                        Text(String(format: "%.1f", adjustmentType.range.lowerBound))
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text(String(format: "%.1f", adjustmentType.range.upperBound))
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                HStack(spacing: 12) {
                    // Reset Button
                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            adjustmentValue = adjustmentType == .brightness || adjustmentType == .blur ? 0 : 1.0
                            updateImage(value: adjustmentValue)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Reset")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                    }
                    
                    // Apply Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingAppliedToast = true
                        }
                        onApply(currentImage)
                        
                        // Hide toast after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingAppliedToast = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Apply Changes")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .overlay(
            // Success Toast
            Group {
                if showingAppliedToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Changes Applied!")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
    }
    
    private var formattedValue: String {
        switch adjustmentType {
        case .brightness, .contrast, .saturation:
            return String(format: "%.2f", adjustmentValue)
        case .blur:
            return String(format: "%.0f px", adjustmentValue)
        }
    }
    
    private func iconForType(_ type: AdjustmentType) -> String {
        switch type {
        case .brightness: return "sun.max.fill"
        case .blur: return "aqi.medium"
        case .contrast: return "circle.lefthalf.filled"
        case .saturation: return "paintpalette.fill"
        }
    }
    
    private func updateImage(value: Double) {
        isProcessing = true
        Task {
            if let edited = await EclipseImageEditor.shared.applyAdjustment(image: originalImage, type: adjustmentType, value: value) {
                await MainActor.run {
                    self.currentImage = edited
                    self.isProcessing = false
                }
            }
        }
    }
}
