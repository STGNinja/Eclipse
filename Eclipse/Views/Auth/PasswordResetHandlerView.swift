//
//  PasswordResetHandlerView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import SwiftUI
import FirebaseAuth

struct PasswordResetHandlerView: View {
    let oobCode: String

    @StateObject private var authManager = AuthManager.shared
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var passwordStrength: PasswordStrength = .weak

    @Environment(\.dismiss) var dismiss

    enum PasswordStrength {
        case weak, medium, strong

        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }

        var text: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient matching your app theme
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showSuccess {
                successView
            } else {
                resetPasswordForm
            }
        }
    }

    // MARK: - Reset Password Form
    private var resetPasswordForm: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 20)

                    Text("Reset Your Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Create a new password for your Eclipse account")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                // Password Fields
                VStack(spacing: 20) {
                    // New Password
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack {
                            if showPassword {
                                TextField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

                        // Password Strength Indicator
                        if !newPassword.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index < strengthLevel ? passwordStrength.color : Color.white.opacity(0.2))
                                        .frame(height: 4)
                                }
                            }

                            Text(passwordStrength.text)
                                .font(.system(size: 12))
                                .foregroundColor(passwordStrength.color)
                        }
                    }

                    // Confirm Password
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack {
                            if showPassword {
                                TextField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

                        // Match Indicator
                        if !confirmPassword.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(passwordsMatch ? .green : .red)
                                Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                    .font(.system(size: 12))
                                    .foregroundColor(passwordsMatch ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 24)
                }

                // Reset Button
                Button {
                    resetPassword()
                } label: {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Reset Password")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .purple.opacity(0.5), radius: 20, y: 10)
                }
                .disabled(!isFormValid || isLoading)
                .opacity(isFormValid && !isLoading ? 1 : 0.5)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Password Requirements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    RequirementRow(met: newPassword.count >= 8, text: "At least 8 characters")
                    RequirementRow(met: containsUppercase, text: "One uppercase letter")
                    RequirementRow(met: containsLowercase, text: "One lowercase letter")
                    RequirementRow(met: containsNumber, text: "One number")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .onChange(of: newPassword) { _, _ in
            calculatePasswordStrength()
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 20)
            }

            VStack(spacing: 16) {
                Text("Password Reset!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("Your password has been successfully reset.\nYou can now sign in with your new password.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Return to Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .purple.opacity(0.5), radius: 20, y: 10)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Views
    private struct RequirementRow: View {
        let met: Bool
        let text: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: met ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(met ? .green : .white.opacity(0.3))
                    .font(.system(size: 12))

                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Computed Properties
    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private var containsUppercase: Bool {
        newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    private var containsLowercase: Bool {
        newPassword.range(of: "[a-z]", options: .regularExpression) != nil
    }

    private var containsNumber: Bool {
        newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }

    private var strengthLevel: Int {
        switch passwordStrength {
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        }
    }

    private var isFormValid: Bool {
        newPassword.count >= 8 &&
        containsUppercase &&
        containsLowercase &&
        containsNumber &&
        passwordsMatch
    }

    // MARK: - Methods
    private func calculatePasswordStrength() {
        var strength = 0

        if newPassword.count >= 8 { strength += 1 }
        if containsUppercase && containsLowercase { strength += 1 }
        if containsNumber { strength += 1 }
        if newPassword.count >= 12 { strength += 1 }
        if newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { strength += 1 }

        if strength <= 2 {
            passwordStrength = .weak
        } else if strength <= 3 {
            passwordStrength = .medium
        } else {
            passwordStrength = .strong
        }
    }

    private func resetPassword() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        print("🔄 Confirming password reset with code...")

        Auth.auth().confirmPasswordReset(withCode: oobCode, newPassword: newPassword) { error in
            isLoading = false

            if let error = error {
                print("❌ Password reset failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                HapticManager.shared.notification(.error)
            } else {
                print("✅ Password reset successful!")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showSuccess = true
                }
                HapticManager.shared.connectedSuccess()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PasswordResetHandlerView(oobCode: "sample-code")
}
