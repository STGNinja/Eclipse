//
//  ConnectionSheetView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct ConnectionSheetView: View {
    let app: EclipseAppInfo
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appManager = AppManager.shared
    var onShowCanvaAuth: (() -> Void)? = nil
    var onShowMusicAuth: (() -> Void)? = nil
    var onShowHealthAuth: (() -> Void)? = nil
    var onConnect: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding()
                
                Spacer()
                
                // Connecting Icons
                HStack(spacing: 20) {
                    // Eclipse logo
                    Image("betterlunr") // Assuming asset name
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Image(systemName: "ellipsis")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    // App Icon
                    AppIconView(app: app, size: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 24)
                
                Text("Connect \(app.name)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 30)
                
                // Disclaimer Box
                VStack(alignment: .leading, spacing: 12) {
                    DisclaimerRow(title: "You're in control", text: "Eclipse always respects your data preferences and is limited to permissions you've explicitly set.")
                    
                    DisclaimerRow(title: "Apps may introduce risk", text: "Eclipse is built to protect your data, but attackers may attempt to use connected apps to access your data.")
                    
                    DisclaimerRow(title: "Data shared with this app", text: "By adding this app, you allow it to access: (1) basic information typically shared when you visit a website, and (2) data from your Eclipse account relevant to your requests.")
                }
                .padding(20)
                .background(Color(white: 0.15))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        print("🕵️ [Debugger] ConnectionSheet: Continue without account tapped")
                        dismiss()
                    } label: {
                        Text("Continue without account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 4)
                    
                    Button {
                        HapticManager.shared.impact(.light)
                        
                        // If it's Canva, trigger parent to show OAuth (don't download yet)
                        if app.id == "canva" {
                            print("🕵️ [Debugger] ConnectionSheet: Connect tapped for Canva. Calling onShowCanvaAuth")
                            dismiss() // Dismiss this sheet so the full screen cover works
                            onShowCanvaAuth?()
                        } else if app.id == "apple_music" {
                             print("🕵️ [Debugger] ConnectionSheet: Connect tapped for Apple Music")
                             appManager.downloadApp(app)
                             onConnect?()
                             dismiss() // Dismiss first
                             // Trigger music auth flow slightly after dismiss
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                  onShowMusicAuth?()
                              }
                        } else if app.id == "health_kit" {
                            print("🕵️ [Debugger] ConnectionSheet: Connect tapped for HealthKit")
                            appManager.downloadApp(app)
                            onConnect?()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onShowHealthAuth?()
                            }
                        } else {
                            // For other apps, download immediately
                            print("🕵️ [Debugger] ConnectionSheet: Connect tapped for \(app.name). Downloading...")
                            appManager.downloadApp(app)
                            onConnect?()
                            dismiss()
                        }
                    } label: {
                        Text("Connect \(app.name)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.hidden)
    }
}

struct DisclaimerRow: View {
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(2)
        }
    }
}
