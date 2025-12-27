//
//  ArtifactsView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import SwiftUI

struct ArtifactsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var artifactsManager = ArtifactsManager.shared
    @State private var showingDeleteAlert = false
    @State private var artifactToDelete: Artifact?
    
    var body: some View {
        ZStack {
            // Dark Theme Background
            Color(red: 0.08, green: 0.08, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    if artifactsManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 100)
                    } else if artifactsManager.artifacts.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "brain.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange.opacity(0.6))
                                .padding(.top, 100)
                            
                            Text("No Artifacts Yet")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            
                            Text("When you share important information with Eclipse, it will be saved here for future reference.")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        // Artifacts Grid
                        LazyVStack(spacing: 16) {
                            ForEach(artifactsManager.artifacts) { artifact in
                                ArtifactCard(artifact: artifact) {
                                    artifactToDelete = artifact
                                    showingDeleteAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationTitle("Artifacts")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.1))
                        )
                }
            }
        }
        .alert("Delete Artifact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let artifact = artifactToDelete {
                    Task {
                        do {
                            try await artifactsManager.deleteArtifact(artifact)
                            HapticManager.shared.notification(.success)
                        } catch {
                            print("Error deleting artifact: \(error)")
                            HapticManager.shared.notification(.error)
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this artifact?")
        }
    }
}

struct ArtifactCard: View {
    let artifact: Artifact
    let onDelete: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Badge
            HStack {
                Label(artifact.category.capitalized, systemImage: categoryIcon)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.3))
                    )
                
                Spacer()
                
                // Delete Button
                Button {
                    HapticManager.shared.impact(.medium)
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.05))
                        )
                }
            }
            
            // Content
            Text(artifact.content)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Timestamp
            Text(artifact.timestamp, style: .relative)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(isPressed ? 0.08 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    private var categoryIcon: String {
        switch artifact.category.lowercased() {
        case "personal":
            return "person.fill"
        case "preferences":
            return "slider.horizontal.3"
        case "facts":
            return "lightbulb.fill"
        default:
            return "star.fill"
        }
    }
}

// Artifact Saved Notification Overlay
struct ArtifactSavedNotification: View {
    @Binding var isShowing: Bool
    let artifact: Artifact?
    
    var body: some View {
        if isShowing, let artifact = artifact {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saved to Artifacts")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(artifact.content.prefix(40) + (artifact.content.count > 40 ? "..." : ""))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowing)
            .onTapGesture {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtifactsView()
    }
}
