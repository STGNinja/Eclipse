//
//  AppsView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct AppsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appManager = AppManager.shared
    @State private var showingStore = false
    var onStartPluginChat: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08)
                    .ignoresSafeArea()
                
                if appManager.myApps.isEmpty {
                    emptyState
                } else {
                    appsList
                }
            }
            .navigationTitle("My Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingStore = true
                    } label: {
                        Image(systemName: "plus.app.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingStore) {
                AppStoreView(onStartPluginChat: onStartPluginChat)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.1))
                .padding(.bottom, 8)
            
            Text("Enhance your Eclipse")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            
            Text("Eclipse Apps are powerful tools that let you do more. Connect to your favorites and supercharge your AI experience.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingStore = true
            } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
            }
            .glassEffect(.regular.tint(.white), in: .capsule)
        }
    }
    
    private var appsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(appManager.myApps) { app in
                    AppRow(app: app) {
                        onStartPluginChat(app.id)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct AppRow: View {
    let app: EclipseAppInfo
    let onStartChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                AppIconView(app: app, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(app.category)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()
            }

            Text(app.description)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)

            HStack(spacing: 12) {
                Button(action: onStartChat) {
                    HStack {
                        Image(systemName: "plus.message.fill")
                        Text("New Chat")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .glassEffect(.regular.tint(Color(hex: app.tintColor).opacity(0.2)).interactive(), in: .capsule)

                Menu {
                    Button(role: .destructive) {
                        AppManager.shared.removeApp(app.id)
                    } label: {
                        Label("Disconnect App", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.tint(.white.opacity(0.05)), in: .circle)
            }
        }
        .padding(20)
        .glassEffect(.regular.tint(.white.opacity(0.03)), in: .rect(cornerRadius: 24))
    }
}
