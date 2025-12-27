//
//  AuthenticationView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.11)
                .ignoresSafeArea()
            
            if isSignUp {
                SignUpView(isSignUp: $isSignUp)
            } else {
                SignInView(isSignUp: $isSignUp)
            }
        }
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @StateObject private var authManager = AuthManager.shared
    @Binding var isSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var showPasswordReset = false
    @State private var currentGreetingIndex = 0

    private let greetings = [
        "Ready to create",
        "Let's get your brain flowing",
        "Welcome back, creator",
        "Time to build something amazing",
        "Your ideas await",
        "Let's make magic happen",
        "Ready to innovate",
        "Your canvas awaits",
        "Let's bring ideas to life",
        "Inspiration starts here",
        "Create without limits",
        "Dream it, build it",
        "Your journey continues",
        "Let's craft brilliance",
        "Ideas become reality here"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Logo with subtle glow
                    ZStack {
                        if let uiImage = UIImage(named: "betterlunr.PNG") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: "moon.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .shadow(color: .orange.opacity(0.3), radius: 30, x: 0, y: 10)
                    .padding(.bottom, 32)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(greetings[currentGreetingIndex])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .id(currentGreetingIndex)
                    }
                    .padding(.bottom, 48)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentGreetingIndex = (currentGreetingIndex + 1) % greetings.count
                            }
                        }
                    }
                    
                    // Input fields container
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                TextField("", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: email.isEmpty) {
                                        Text("your@email.com")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Button {
                                    HapticManager.shared.impact(.light)
                                    showPasswordReset = true
                                } label: {
                                    Text("Forgot?")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                SecureField("", text: $password)
                                    .textContentType(.password)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter password")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    
                    // Sign In Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        Task {
                            await signIn()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
                    
                    // Divider
                    HStack(spacing: 16) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
                    
                    // Google Sign In Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        Task {
                            await signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .disabled(isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    
                    // Sign Up Link
                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button {
                            HapticManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSignUp = true
                            }
                        } label: {
                            Text("Sign Up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView(email: $email)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.impact(.light)
            }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred")
        }
    }
    
    private func signIn() async {
        isLoading = true
        
        do {
            try await authManager.signIn(email: email, password: password)
            HapticManager.shared.notification(.success)
        } catch {
            HapticManager.shared.notification(.error)
            showError = true
        }
        
        isLoading = false
    }
    
    private func signInWithGoogle() async {
        isLoading = true

        do {
            try await authManager.signInWithGoogle()
            HapticManager.shared.notification(.success)
        } catch {
            // Don't show error for user cancellation
            let nsError = error as NSError

            if !(nsError.domain == "com.google.GIDSignIn" && nsError.code == -5) {
                HapticManager.shared.notification(.error)
                showError = true
            }
        }

        isLoading = false
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @StateObject private var authManager = AuthManager.shared
    @Binding var isSignUp: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentGreetingIndex = 0

    private let greetings = [
        "Ready to create",
        "Let's get your brain flowing",
        "Start your creative journey",
        "Your ideas deserve a home",
        "Build something incredible",
        "Join the creators",
        "Unleash your imagination",
        "Create without limits",
        "Your canvas awaits",
        "Dream it, build it",
        "Transform ideas into reality",
        "Innovation starts here",
        "Craft your masterpiece",
        "Make magic happen",
        "Begin your adventure"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo with subtle glow
                    ZStack {
                        if let uiImage = UIImage(named: "betterlunr.PNG") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                        } else {
                            Image(systemName: "moon.circle.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .shadow(color: .orange.opacity(0.3), radius: 30, x: 0, y: 10)
                    .padding(.bottom, 28)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(greetings[currentGreetingIndex])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .id(currentGreetingIndex)
                    }
                    .padding(.bottom, 40)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentGreetingIndex = (currentGreetingIndex + 1) % greetings.count
                            }
                        }
                    }
                    
                    // Input fields container
                    VStack(spacing: 14) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                TextField("", text: $name)
                                    .textContentType(.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: name.isEmpty) {
                                        Text("Your name")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                TextField("", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: email.isEmpty) {
                                        Text("your@email.com")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                SecureField("", text: $password)
                                    .textContentType(.newPassword)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: password.isEmpty) {
                                        Text("At least 6 characters")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                        
                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 24)
                                
                                SecureField("", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .tint(.orange)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Re-enter password")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .glassEffect(.regular, in: .capsule)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    
                    // Create Account Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        Task {
                            await signUp()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
                    
                    // Divider
                    HStack(spacing: 16) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
                    
                    // Google Sign In Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        Task {
                            await signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .disabled(isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    
                    // Sign In Link
                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button {
                            HapticManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSignUp = false
                            }
                        } label: {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.impact(.light)
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func signUp() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            HapticManager.shared.notification(.error)
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            HapticManager.shared.notification(.error)
            return
        }
        
        isLoading = true
        
        do {
            try await authManager.signUp(email: email, password: password, displayName: name)
            HapticManager.shared.notification(.success)
        } catch {
            errorMessage = authManager.errorMessage ?? "An error occurred"
            HapticManager.shared.notification(.error)
            showError = true
        }
        
        isLoading = false
    }
    
    private func signInWithGoogle() async {
        isLoading = true

        do {
            try await authManager.signInWithGoogle()
            HapticManager.shared.notification(.success)
        } catch {
            // Don't show error for user cancellation
            let nsError = error as NSError

            if !(nsError.domain == "com.google.GIDSignIn" && nsError.code == -5) {
                errorMessage = authManager.errorMessage ?? "An error occurred"
                HapticManager.shared.notification(.error)
                showError = true
            }
        }

        isLoading = false
    }
}

// MARK: - Password Reset View

struct PasswordResetView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    
    @State private var resetEmail = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        HapticManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.bottom, 32)
                
                // Title
                VStack(spacing: 12) {
                    Text("Reset Password")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 48)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.leading, 24)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 24)
                        
                        TextField("", text: $resetEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .tint(.orange)
                            .placeholder(when: resetEmail.isEmpty) {
                                Text("your@email.com")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .glassEffect(.regular, in: .capsule)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Send Reset Link Button
                Button {
                    HapticManager.shared.impact(.medium)
                    Task {
                        await sendResetLink()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                            
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                .disabled(isLoading || resetEmail.isEmpty)
                .opacity(resetEmail.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            // Pre-fill with email from sign-in if available
            if !email.isEmpty {
                resetEmail = email
            }
        }
        .alert("Check Your Email", isPresented: $showSuccess) {
            Button("OK") {
                HapticManager.shared.impact(.light)
                dismiss()
            }
        } message: {
            Text("Password reset link sent to \(resetEmail)\n\n✓ Check your inbox\n✓ Check spam/junk folder\n✓ Email may take 1-5 minutes\n\nIf you don't receive it, verify the email address and try again.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.impact(.light)
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendResetLink() async {
        isLoading = true
        
        do {
            try await authManager.resetPassword(email: resetEmail)
            HapticManager.shared.notification(.success)
            showSuccess = true
            // Update the parent email field
            email = resetEmail
        } catch {
            HapticManager.shared.notification(.error)
            errorMessage = authManager.errorMessage ?? "Failed to send reset link"
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
}
