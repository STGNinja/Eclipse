//
//  AppStoreView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct AppStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appManager = AppManager.shared
    @State private var searchText = ""
    @State private var selectedCategory = "Featured"
    var onStartPluginChat: (String) -> Void

    let categories = ["Featured", "Lifestyle", "Productivity", "Design", "Music", "Travel"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header
                    VStack(spacing: 16) {
                        // Title with X button
                        ZStack {
                            Text("") // Hiding title as requested
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            HStack {
                                Spacer()
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("Search apps", text: $searchText)
                                .foregroundStyle(.white)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    .background(
                        Color.black
                            .ignoresSafeArea(edges: .top)
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {

                            // Featured Card (Hero)
                            if searchText.isEmpty && selectedCategory == "Featured" {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        // Apple Weather Card
                                        if let weatherApp = appManager.availableApps.first(where: { $0.id == "apple_weather" }) {
                                            FeaturedHeroCard(app: weatherApp, adImageName: "weatherad", onStartPluginChat: onStartPluginChat)
                                                .containerRelativeFrame(.horizontal) // Makes it snap nicely/full width relative to container if needed, or use fixed frame
                                                .frame(width: UIScreen.main.bounds.width - 40) // Full width minus padding
                                        }
                                        
                                        // Canva Card
                                        if let canva = appManager.availableApps.first(where: { $0.id == "canva" }) {
                                            FeaturedHeroCard(app: canva, adImageName: "canvalog", onStartPluginChat: onStartPluginChat)
                                                .frame(width: UIScreen.main.bounds.width - 40)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .scrollTargetLayout()
                                }
                                .scrollTargetBehavior(.viewAligned) // Snapping behavior
                                
                                Text("Chat with your favorite apps in Eclipse")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 10)
                            }

                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 24) {
                                    ForEach(categories, id: \.self) { category in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedCategory = category
                                            }
                                        } label: {
                                            VStack(spacing: 8) {
                                                Text(category)
                                                    .font(.system(size: 16, weight: selectedCategory == category ? .bold : .medium))
                                                    .foregroundStyle(selectedCategory == category ? .white : .white.opacity(0.5))
                                                
                                                if selectedCategory == category {
                                                    Capsule()
                                                        .fill(.white)
                                                        .frame(width: 20, height: 3)
                                                        .matchedGeometryEffect(id: "cat_under", in: categoryNamespace)
                                                } else {
                                                    Capsule()
                                                        .fill(.clear)
                                                        .frame(width: 20, height: 3)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            // App List
                            VStack(alignment: .leading, spacing: 24) {
                                ForEach(filteredApps) { app in
                                    StoreListRow(app: app, onStartPluginChat: onStartPluginChat)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @Namespace private var categoryNamespace

    var filteredApps: [EclipseAppInfo] {
        if !searchText.isEmpty {
            return appManager.availableApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedCategory == "Featured" {
            // Updated to exclude the featured weather app from the list to avoid duplication if desired, 
            // but usually featured apps are also in the list. Keeping as is.
            return appManager.availableApps
        }
        return appManager.availableApps.filter { $0.category == selectedCategory }
    }
}

// MARK: - Featured Hero Card

struct FeaturedHeroCard: View {
    let app: EclipseAppInfo
    let adImageName: String
    var onStartPluginChat: (String) -> Void

    var body: some View {
        NavigationLink(destination: AppDetailView(app: app, onConnect: {
            onStartPluginChat(app.id)
        })) {
            ZStack {
                // Load the custom ad image
                if let uiImage = loadAdImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.08) // Slightly zoomed in to hide edges
                        .frame(width: UIScreen.main.bounds.width - 30, height: 220) // Wider frame
                        .clipped()
                } else {
                    // Fallback to gradient if image not found
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: app.tintColor).opacity(0.6), Color(hex: app.tintColor).opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 14) {
                                AppIconView(app: app, size: 48)
                                    .shadow(radius: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(app.description)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Text("View")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                            
                            // Command Bubble
                            if let command = app.commandPreview {
                                HStack(spacing: 8) {
                                    Text(command)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                }
                                .padding(.bottom, 30)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 10) // Reduced padding for wider appearance
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func loadAdImage() -> UIImage? {
        // Try to load named image
        if let image = UIImage(named: adImageName) {
            return image
        }
        
        // Try with extension
        let extensions = ["png", "jpg", "jpeg", "webp"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: adImageName, ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        
        return nil
    }
}

// MARK: - List Row

struct StoreListRow: View {
    let app: EclipseAppInfo
    var onStartPluginChat: (String) -> Void

    var body: some View {
        NavigationLink(destination: AppDetailView(app: app, onConnect: {
            onStartPluginChat(app.id)
        })) {
            ZStack {
                // Soft gradient background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: app.tintColor).opacity(0.15),
                                Color(hex: app.tintColor).opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                HStack(spacing: 16) {
                    AppIconView(app: app, size: 60)
                        .shadow(color: Color(hex: app.tintColor).opacity(0.3), radius: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)

                        Text(app.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(2)
                    }

                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
