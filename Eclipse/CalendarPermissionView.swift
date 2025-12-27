//
//  CalendarPermissionView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import SwiftUI
internal import EventKit

struct CalendarPermissionView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.11)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Text Content
                VStack(spacing: 16) {
                    Text("Calendar Access")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Eclipse needs full calendar access to create and manage events for you through voice commands.")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Permission Status
                if calendarManager.permissionStatus != .notDetermined {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)

                            Text(statusText)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())

                        if calendarManager.permissionStatus == .denied || calendarManager.permissionStatus == .restricted {
                            Text("Open Settings > Privacy > Calendars > Eclipse and enable Full Access")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    if calendarManager.permissionStatus == .notDetermined {
                        Button {
                            HapticManager.shared.impact(.medium)
                            requestPermission()
                        } label: {
                            HStack(spacing: 10) {
                                if isRequesting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                }
                                Text(isRequesting ? "Requesting..." : "Enable Calendar Access")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
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
                            .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)
                        }
                        .disabled(isRequesting)
                        .padding(.horizontal, 32)
                    } else if calendarManager.permissionStatus == .denied || calendarManager.permissionStatus == .restricted {
                        Button {
                            HapticManager.shared.impact(.light)
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                Text("Open Settings")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            HapticManager.shared.impact(.light)
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Done")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.green.opacity(0.8), .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    }

                    Button {
                        HapticManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var statusColor: Color {
        if #available(iOS 17.0, *) {
            switch calendarManager.permissionStatus {
            case .fullAccess, .writeOnly: return .green
            case .denied, .restricted: return .red
            default: return .orange
            }
        } else {
            switch calendarManager.permissionStatus {
            case .authorized: return .green
            case .denied, .restricted: return .red
            default: return .orange
            }
        }
    }

    private var statusText: String {
        if #available(iOS 17.0, *) {
            switch calendarManager.permissionStatus {
            case .fullAccess: return "Full Access Granted"
            case .writeOnly: return "Write Access Granted"
            case .denied: return "Access Denied"
            case .restricted: return "Access Restricted"
            default: return "Not Determined"
            }
        } else {
            switch calendarManager.permissionStatus {
            case .authorized: return "Access Granted"
            case .denied: return "Access Denied"
            case .restricted: return "Access Restricted"
            default: return "Not Determined"
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await calendarManager.requestAccess()
            await MainActor.run {
                isRequesting = false
                if granted {
                    HapticManager.shared.notification(.success)
                    // Dismiss after a brief delay to show success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
}
