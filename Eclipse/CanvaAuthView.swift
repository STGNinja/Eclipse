//
//  CanvaAuthView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI
import AuthenticationServices

struct CanvaAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // We keep a reference to the session so it's not deallocated
    @State private var authSession: ASWebAuthenticationSession?
    
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Landing Screen Content
            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(24)
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.app.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 16) {
                    Text("Connect to Canva")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    
                    Text("Unleash your creativity with AI-powered design tools.")
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Connecting...")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                }
                
                Spacer()
                
                Button {
                    startAuthSession()
                } label: {
                    Text("Continue to Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .cornerRadius(20)
                        .padding(.horizontal, 32)
                }
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.6 : 1.0)
                
                Text("Secure verification via Safari")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
        .alert("Canva Connection", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        // Auto-start on appear if desired, or wait for user tap (preferred for ASWebAuthSession permissions)
        .onAppear {
            print("🕵️ [CanvaAuth] View appeared.")
        }
    }
    
    private func startAuthSession() {
        print("🕵️ [CanvaAuth] Starting ASWebAuthenticationSession...")
        HapticManager.shared.impact(.medium)
        
        guard let authURL = CanvaService.shared.getAuthorizationURL() else {
            errorMessage = "Could not generate authorization URL."
            return
        }
        
        // Define the scheme we expect the callback to have.
        // If your redirect URI is 'https://eclipse-ai.app/oauth/canva', the scheme is 'https'.
        // The bridge page redirects to 'eclipse://oauth/canva', so the scheme is 'eclipse'.
        let callbackScheme = "eclipse"
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
            
            // Release the session reference
            self.authSession = nil
            
            if let error = error {
                // Check for user cancellation (ASWebAuthenticationSessionErrorCode.canceledLogin)
                // Code 1 is canceled.
                let nsError = error as NSError
                if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    print("🕵️ [CanvaAuth] User canceled.")
                    return
                }
                
                print("🕵️ [CanvaAuth] Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
                return
            }
            
            guard let callbackURL = callbackURL else {
                print("🕵️ [CanvaAuth] No callback URL returned.")
                return
            }
            
            print("🕵️ [CanvaAuth] Success! Callback detected: \(callbackURL.absoluteString)")
            handleCallback(url: callbackURL)
        }
        
        // Context provider is optional on SwiftUI if we don't need strict window anchoring,
        // but often required to quiet console warnings or strictly attach to window.
        // For simple usage, we can set the provider to a simple helper class.
        let contextProvider = PresentationContextProvider()
        session.presentationContextProvider = contextProvider
        
        // ⚠️ IMPORTANT: 'prefersEphemeralWebBrowserSession' = false shares cookies with Safari.
        // This is exactly what we want to fix the "Login Loop" (Google remembers you).
        session.prefersEphemeralWebBrowserSession = false
        
        self.authSession = session
        session.start()
    }
    
    private func handleCallback(url: URL) {
        // Validate it uses the 'eclipse' scheme
        // Example: eclipse://oauth/canva?code=...
        guard url.scheme == "eclipse" else {
            print("🕵️ [CanvaAuth] Callback Scheme mismatch: \(url.absoluteString)")
            return
        }
        
        // Extract code
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            
            // Check for error param
            if url.absoluteString.contains("error=") {
                DispatchQueue.main.async {
                    self.errorMessage = "Authorization was denied by Canva."
                }
            }
            return
        }
        
        print("🕵️ [CanvaAuth] OAuth Code captured: \(code)")
        isProcessing = true
        
        Task {
            do {
                _ = try await CanvaService.shared.exchangeCodeForToken(code: code)
                await MainActor.run {
                    print("🕵️ [CanvaAuth] Token exchange success.")
                    HapticManager.shared.notification(.success)
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("🕵️ [CanvaAuth] Token exchange failed: \(error)")
                    errorMessage = "Failed to complete connection. Please try again."
                    isProcessing = false
                }
            }
        }
    }
}

// Helper for ASWebAuthenticationSession presentation
class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the actual key window of the active scene
        
        // 1. Try to find the active scene's key window
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        
        // 2. Fallback: just return the first window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let firstWindow = windowScene.windows.first {
            return firstWindow
        }
        
        // 3. Absolute fallback (creates a new window, which might not work but is better than crashing)
        return ASPresentationAnchor()
    }
}
