//
//  SettingsView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var historyService: HistoryService
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var hybridRouter = HybridAIRouter.shared
    @State private var showingSignOutAlert = false
    @State private var showingAuthSheet = false
    @State private var showingProfile = false
    @State private var showingTerms = false
    @State private var hapticFeedbackEnabled = true
    @State private var privacyMode = UserDefaults.standard.bool(forKey: "privacyModeEnabled")
    @State private var selectedAIPreference = HybridAIRouter.shared.aiPreference

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.11, green: 0.11, blue: 0.11)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        SettingsSection("Account") {
                            HStack {
                                Text(authManager.userEmail)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                                Text("Signed in")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.green.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            Button {
                                showingProfile = true
                                HapticManager.shared.impact(.light)
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.circle")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.orange)
                                        .frame(width: 28)

                                    Text("Profile")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            SettingsRow(
                                icon: "dollarsign.circle",
                                title: "Billing",
                                subtitle: "Pro plan",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )
                        }

                        // Intelligence Section
                        SettingsSection("Intelligence") {
                            NavigationLink(destination: AISettingsView(
                                privacyMode: $privacyMode,
                                selectedAIPreference: $selectedAIPreference
                            )) {
                                HStack(spacing: 16) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.purple)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("AI Model")
                                            .font(.system(size: 17))
                                            .foregroundStyle(.white)
                                        
                                        Text(selectedAIPreference.displayName)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticManager.shared.impact(.light)
                            })

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            NavigationLink(destination: CapabilitiesView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.orange)
                                        .frame(width: 28)
                                    
                                    Text("Capabilities")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            SettingsRow(
                                icon: "app.connected.to.app.below.fill",
                                title: "Integrations",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )
                        }

                        // Preferences Section
                        SettingsSection("Preferences") {
                            NavigationLink(destination: AppearanceView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "paintbrush")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.orange)
                                        .frame(width: 28)
                                    
                                    Text("Appearance")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticManager.shared.impact(.light)
                            })

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            SettingsRow(
                                icon: "globe",
                                title: "Speech language",
                                subtitle: "EN",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            SettingsRow(
                                icon: "bell",
                                title: "Notifications",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                            HStack(spacing: 16) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                                    .frame(width: 28)

                                Text("Haptic feedback")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)

                                Spacer()

                                Toggle("", isOn: $hapticFeedbackEnabled)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }

                        // Privacy & Safety Section
                        SettingsSection("Privacy & Safety") {
                            SettingsRow(
                                icon: "shield",
                                title: "Privacy",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 60)

                            SettingsRow(
                                icon: "link",
                                title: "Shared links",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )

                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 60)

                            SettingsRow(
                                icon: "square.on.square",
                                title: "Permissions",
                                action: {
                                    HapticManager.shared.impact(.light)
                                }
                            )
                        }

                        // Session Section
                        SettingsSection("Session") {
                            Button {
                                HapticManager.shared.impact(.medium)
                                showingSignOutAlert = true
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.red)
                                        .frame(width: 28)

                                    Text("Log out")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.red)

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.impact(.light)
                        showingTerms = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(historyService: historyService)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 32)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .disabled(action == nil)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(historyService: HistoryService())
}
// MARK: - Capabilities View

struct CapabilitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isCalendarEnabled") private var isCalendarEnabled = false
    @StateObject private var calendarManager = CalendarManager.shared
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.11)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("Enable specific capabilities to give Eclipse more power. You remain in control of permissions.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    VStack(spacing: 12) {
                        // Apple Calendar
                        HStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 22))
                                .foregroundStyle(isCalendarEnabled ? .red : .white.opacity(0.3))
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Calendar")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                                
                                Text("Read & Schedule Events")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isCalendarEnabled)
                                .labelsHidden()
                                .tint(.orange)
                                .onChange(of: isCalendarEnabled) { newValue in
                                    if newValue {
                                        Task {
                                            _ = await calendarManager.requestAccess()
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        
                        // Eclipse Live Voice
                        NavigationLink(destination: EclipseLiveVoiceView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.purple)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Eclipse Live")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.white)
                                    
                                    Text("Voice & Audio Settings")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle("Capabilities")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}



// MARK: - Profile Info Card

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - AI Settings View
struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var privacyMode: Bool
    @Binding var selectedAIPreference: AIPreference
    @StateObject private var appleService = AppleIntelligenceService.shared
    @StateObject private var hybridRouter = HybridAIRouter.shared
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.11)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eclipse uses a hybrid AI system that intelligently routes between Apple Intelligence (on-device) and Google Gemini (cloud-based) for the best balance of privacy, performance, and cost.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }
                    
                    // Apple Intelligence Status
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                            Text("Apple Intelligence Status")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(appleService.isAvailable ? Color.green : Color.red)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appleService.isAvailable ? "Available" : "Not Available")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)

                                if let reason = appleService.unavailabilityReason {
                                    Text(reason)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    // Privacy Mode Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 18))
                                .foregroundStyle(.blue)
                            Text("Privacy Mode")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: Binding(
                                get: { privacyMode },
                                set: { newValue in
                                    privacyMode = newValue
                                    hybridRouter.privacyMode = newValue
                                    HapticManager.shared.impact(.medium)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use on-device processing only")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)

                                    Text("When enabled, all queries use Apple Intelligence. Cloud AI (Gemini) is only used for features that require it (like image generation).")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .tint(.blue)
                            .disabled(!appleService.isAvailable)

                            if !appleService.isAvailable {
                                Text("Apple Intelligence must be available to enable Privacy Mode")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    // AI Model Preference
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 18))
                                .foregroundStyle(.purple)
                            Text("AI Model Preference")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            ForEach(AIPreference.allCases, id: \.self) { preference in
                                Button {
                                    HapticManager.shared.impact(.light)
                                    selectedAIPreference = preference
                                    hybridRouter.aiPreference = preference
                                } label: {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preference.displayName)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(.white)

                                            Text(preference.description)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.6))
                                                .multilineTextAlignment(.leading)
                                        }

                                        Spacer()

                                        if selectedAIPreference == preference {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(.purple)
                                        } else {
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if preference != AIPreference.allCases.last {
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 20)
                                }
                            }
                        }
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    // Cost Savings Info (if available)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                            Text("Cost Savings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By using Apple Intelligence when possible, Eclipse reduces cloud AI costs while maintaining privacy.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("On-Device")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Free & Private")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.green)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Cloud AI")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("When Needed")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    // Feature Comparison
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 18))
                                .foregroundStyle(.orange)
                            Text("Feature Comparison")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            FeatureRow(
                                feature: "Text Generation",
                                appleSupport: true,
                                geminiSupport: true
                            )
                            Divider().background(Color.white.opacity(0.1))

                            FeatureRow(
                                feature: "Image Analysis",
                                appleSupport: false,
                                geminiSupport: true
                            )
                            Divider().background(Color.white.opacity(0.1))

                            FeatureRow(
                                feature: "Image Generation",
                                appleSupport: false,
                                geminiSupport: true
                            )
                            Divider().background(Color.white.opacity(0.1))

                            FeatureRow(
                                feature: "Voice Conversations",
                                appleSupport: false,
                                geminiSupport: true
                            )
                            Divider().background(Color.white.opacity(0.1))

                            FeatureRow(
                                feature: "Privacy (On-Device)",
                                appleSupport: true,
                                geminiSupport: false
                            )
                            Divider().background(Color.white.opacity(0.1))

                            FeatureRow(
                                feature: "Web Search",
                                appleSupport: false,
                                geminiSupport: true
                            )
                        }
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("AI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: String
    let appleSupport: Bool
    let geminiSupport: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Text(feature)
                .font(.system(size: 14))
                .foregroundStyle(.white)
            
            Spacer()
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                    Image(systemName: appleSupport ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(appleSupport ? .green : .white.opacity(0.3))
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                    Image(systemName: geminiSupport ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(geminiSupport ? .green : .white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}


