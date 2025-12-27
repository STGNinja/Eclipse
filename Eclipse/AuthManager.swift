//
//  AuthManager.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import Combine
import GoogleSignIn

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    static let shared = AuthManager()

    private init() {
        // Check for current user
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Refresh User Data
    
    func refreshUserData() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            try await currentUser.reload()
            await MainActor.run {
                self.user = Auth.auth().currentUser
                self.objectWillChange.send()
            }
            print("✅ User data refreshed")
        } catch {
            print("❌ Error refreshing user data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign In with Email
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
            print("✅ Successfully signed in: \(result.user.email ?? "No email")")
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sign Up with Email
    
    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
            print("✅ Successfully created account: \(result.user.email ?? "No email")")
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sign In with Google

    func signInWithGoogle() async throws {
        // Get the client ID from Firebase configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing client ID"])
        }

        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        print("🔐 Starting Google Sign-In...")

        do {
            // Get the root view controller on main thread - simplified approach
            guard let viewController = await getRootViewController() else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            }

            print("   Presenting from: \(type(of: viewController))")

            // Start Google Sign-In flow
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

            guard let idToken = signInResult.user.idToken?.tokenString else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }

            let accessToken = signInResult.user.accessToken.tokenString

            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)

            await MainActor.run {
                self.user = authResult.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }

            print("✅ Successfully signed in with Google: \(authResult.user.email ?? "No email")")
        } catch let error as NSError {
            // Handle cancellation gracefully
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                print("ℹ️ Google Sign-In cancelled by user")
                await MainActor.run {
                    self.errorMessage = nil // Don't set error for user cancellation
                }
            } else {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Google sign in error: \(error.localizedDescription)")
                print("   Domain: \(error.domain), Code: \(error.code)")
            }
            throw error
        }
    }

    // MARK: - Helper to Get Root View Controller
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        // Find the key window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? 
            UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("❌ No window scene found")
            return nil
        }
        
        // Get the key window
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? 
              windowScene.windows.first else {
            print("❌ No key window found")
            return nil
        }
        
        // Return the root view controller (no need to traverse)
        // Google Sign-In SDK handles presenting on top of whatever is there
        return window.rootViewController
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut() // Also sign out from Google
            
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                self.errorMessage = nil
            }
            
            print("✅ Successfully signed out")
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        print("🔄 Attempting to send password reset email to: \(email)")

        // Validate email format first
        guard email.contains("@") && email.contains(".") else {
            let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
            await MainActor.run {
                self.errorMessage = "Please enter a valid email address"
            }
            print("❌ Invalid email format: \(email)")
            throw error
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error as NSError? {
                print("❌ Password reset failed: \(error.localizedDescription)")
                print("   Error code: \(error.code)")
                print("   Domain: \(error.domain)")
                print("   Details: \(error.userInfo)")
                
                // Provide more helpful logs in the console
                if error.code == 17011 { // User not found
                    print("   → This email is not registered in Firebase")
                } else if error.code == 17009 { // Invalid email
                    print("   → Email format is invalid")
                } else if error.code == 17010 { // Network error
                    print("   → Network connection issue")
                }

                Task { @MainActor in
                    if error.code == 17011 {
                        self.errorMessage = "This email is not registered. Please check the email address or sign up."
                    } else if error.userInfo.description.contains("RESET_PASSWORD_EXCEED_LIMIT") {
                        self.errorMessage = "Too many requests. Please wait about 15 minutes before trying again."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                }
                return
            }
            
            print("✅ Password reset email sent successfully to \(email)")
            print("   📧 Check your inbox and spam/junk folder")
            print("   ⏰ Email should arrive within 1-5 minutes")
            print("   📱 Sender: noreply@firebase (or your custom domain)")
            print("   ⚠️ If you don't receive it:")
            print("      1. Check spam/junk folder")
            print("      2. Verify the email address is correct")
            print("      3. Check Firebase Console → Authentication → Templates")
            print("      4. Wait a few minutes and try again")
        }
    }
    
    // MARK: - Helper Properties
    
    var userEmail: String {
        user?.email ?? "No email"
    }
    
    var userName: String {
        user?.displayName ?? "User"
    }
    
    var userInitial: String {
        String(userName.prefix(1).uppercased())
    }
    
    var userPhotoURL: URL? {
        user?.photoURL
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        guard let user = user else { return }
        
        do {
            try await user.delete()
            
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
                self.errorMessage = nil
            }
            
            print("✅ Successfully deleted account")
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Delete account error: \(error.localizedDescription)")
            throw error
        }
    }
}
