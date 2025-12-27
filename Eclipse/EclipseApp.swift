//
//  EclipseApp.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Initialize voice preferences manager early to ensure it loads before first use
        _ = VoicePreferencesManager.shared
        print("🎤 Voice preferences manager initialized on app launch")

        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct EclipseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager: AuthManager
    @State private var resetPasswordCode: String?
    @State private var showSplash = true

    init() {
        _authManager = StateObject(wrappedValue: AuthManager.shared)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main Content View hierarchy
                Group {
                    if authManager.isAuthenticated {
                        ContentView()
                    } else {
                        AuthenticationView()
                    }
                }
                
                // Splash Screen Overlay
                if showSplash {
                    SplashView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 1.1))
                        ))
                        .onAppear {
                            // Slightly decreased delay for a faster feel (2.5s -> 1.8s)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
            .sheet(item: Binding(
                get: { resetPasswordCode.map { PasswordResetWrapper(code: $0) } },
                set: { resetPasswordCode = $0?.code }
            )) { wrapper in
                PasswordResetHandlerView(oobCode: wrapper.code)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    // MARK: - Deep Link Handling
    private func handleIncomingURL(_ url: URL) {
        print("🔗 Received URL: \(url.absoluteString)")

        // Handle Firebase password reset links
        if url.host == "eclipse-2a42b.firebaseapp.com" || url.host == "www.eclipse-app.com" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let queryItems = components.queryItems {

                // Check for password reset action
                if let mode = queryItems.first(where: { $0.name == "mode" })?.value,
                   mode == "resetPassword",
                   let oobCode = queryItems.first(where: { $0.name == "oobCode" })?.value {

                    print("✅ Password reset link detected")
                    print("   Code: \(oobCode)")

                    // Show custom password reset view
                    resetPasswordCode = oobCode
                }
            }
        }
    }
}

// Helper struct for identifiable binding
struct PasswordResetWrapper: Identifiable {
    let id = UUID()
    let code: String
}
