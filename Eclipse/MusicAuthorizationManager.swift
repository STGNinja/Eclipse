//
//  MusicAuthorizationManager.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import Foundation
import MusicKit
import SwiftUI
import Combine

/// Centralized manager for MusicKit authorization
class MusicAuthorizationManager: ObservableObject {
    static let shared = MusicAuthorizationManager()

    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var hasSubscription: Bool = false
    @Published var errorMessage: String?

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Check current authorization status
    @MainActor
    func checkAuthorizationStatus() async {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        isAuthorized = (status == .authorized)
        
        if isAuthorized {
            await checkSubscription()
        }

        print("🎵 MusicKit Authorization Status: \(status)")
    }

    /// Check Apple Music subscription status
    @MainActor
    func checkSubscription() async {
        do {
            let subscription = try await MusicSubscription.current
            hasSubscription = subscription.canPlayCatalogContent
            print("🎵 Apple Music Subscription: \(hasSubscription ? "Active" : "None/Inactive")")
        } catch {
            print("❌ Subscription check failed: \(error)")
            hasSubscription = false
        }
    }

    /// Request authorization from user
    @MainActor
    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = (status == .authorized)

        if isAuthorized {
            print("✅ MusicKit authorization granted")
            errorMessage = nil
            await checkSubscription()
        } else {
            print("❌ MusicKit authorization denied or restricted")
            errorMessage = getErrorMessage(for: status)
        }

        return isAuthorized
    }

    /// Get user-friendly error message for authorization status
    private func getErrorMessage(for status: MusicAuthorization.Status) -> String {
        switch status {
        case .notDetermined:
            return "Please allow Eclipse to access your Apple Music library"
        case .denied:
            return "Music library access denied. Enable in Settings > Eclipse > Media & Apple Music"
        case .restricted:
            return "Music library access is restricted on this device"
        case .authorized:
            return nil ?? ""
        @unknown default:
            return "Unknown authorization status"
        }
    }

    /// Check if authorization is needed and request if necessary
    @MainActor
    func ensureAuthorization() async -> Bool {
        if isAuthorized {
            return true
        }
        return await requestAuthorization()
    }
}
