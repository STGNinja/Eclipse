//
//  HapticManager.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import UIKit
import CoreHaptics

/// A manager class for providing haptic feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var speechHapticTimer: Timer?

    private init() {
        setupHapticEngine()
    }

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            // Restart engine if it stops
            engine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                self?.setupHapticEngine()
            }

            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    /// Generates an impact haptic feedback
    /// - Parameter style: The intensity of the impact
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Generates a notification haptic feedback
    /// - Parameter type: The type of notification (success, warning, or error)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Generates a selection haptic feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Advanced Speech-Synced Haptics

    /// Start continuous haptic feedback synced to AI speech
    func startSpeechHaptics(audioLevel: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            // Create a gentle pulsing pattern that syncs with speech
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, audioLevel * 2))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play speech haptic: \(error)")
        }
    }

    /// Rhythmic pulse for AI speaking
    func aiSpeakingPulse() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            var events = [CHHapticEvent]()

            // Create a subtle rhythmic pulse (like a heartbeat)
            for i in 0..<2 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: i == 0 ? 0.6 : 0.4)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: TimeInterval(i) * 0.15
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play AI pulse: \(error)")
        }
    }

    /// User speaking acknowledgment
    func userSpeakingAck() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play user ack: \(error)")
        }
    }

    /// Connected success haptic
    func connectedSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            var events = [CHHapticEvent]()

            // Rising crescendo
            for i in 0..<3 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 + Float(i) * 0.2)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: TimeInterval(i) * 0.1
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play connected success: \(error)")
        }
    }
}
