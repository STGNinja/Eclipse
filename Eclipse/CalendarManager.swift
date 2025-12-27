import Foundation
internal import EventKit
import SwiftUI
import Combine

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let store = EKEventStore()
    
    @Published var permissionStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        updatePermissionStatus()
    }
    
    func updatePermissionStatus() {
        self.permissionStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    @MainActor
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
                print("📅 Requested full access to events: \(granted)")
            } else {
                granted = try await store.requestAccess(to: .event)
                print("📅 Requested access to events: \(granted)")
            }
            updatePermissionStatus()

            // Additional verification
            if granted {
                let currentStatus = EKEventStore.authorizationStatus(for: .event)
                print("📅 Current authorization status after request: \(currentStatus.rawValue)")
            }

            return granted
        } catch {
            print("❌ Calendar access error: \(error)")
            return false
        }
    }
    
    func getUpcomingEvents(days: Int = 7) -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized || 
              EKEventStore.authorizationStatus(for: .event) == .fullAccess else { 
            print("⚠️ Calendar access not authorized")
            return [] 
        }
        
        let calendars = store.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = store.events(matching: predicate)
        
        return events.sorted { $0.startDate < $1.startDate }
    }
    
    func addEvent(title: String, date: Date, durationSeconds: TimeInterval = 3600, notes: String? = nil) async -> Bool {
        // Check authorization
        let authStatus = EKEventStore.authorizationStatus(for: .event)

        print("📅 [Calendar] Current auth status: \(authStatus.rawValue)")

        // iOS 17+ uses different authorization statuses
        let isAuthorized: Bool
        if #available(iOS 17.0, *) {
            isAuthorized = (authStatus == .fullAccess || authStatus == .writeOnly)
        } else {
            isAuthorized = (authStatus == .authorized)
        }

        if !isAuthorized {
            print("⚠️ Calendar access not authorized, current status: \(authStatus.rawValue)")

            // Try to request access if not determined
            if authStatus == .notDetermined {
                print("🔑 Requesting calendar access...")
                let granted = await requestAccess()
                if !granted {
                    print("❌ Calendar access denied")
                    return false
                }

                // Double check after request
                let newStatus = EKEventStore.authorizationStatus(for: .event)
                print("📅 Status after request: \(newStatus.rawValue)")
            } else {
                print("❌ Calendar permission required. Please enable in Settings > Privacy > Calendars")
                return false
            }
        }

        print("📅 Creating calendar event: '\(title)' at \(date)")

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date
        event.endDate = date.addingTimeInterval(durationSeconds)
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents

        // Use default calendar or first writable calendar
        if let defaultCalendar = store.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
            print("✅ Using default calendar: \(defaultCalendar.title)")
        } else {
            // Find first writable calendar
            let writableCalendars = store.calendars(for: .event).filter { $0.allowsContentModifications }
            if let firstWritable = writableCalendars.first {
                event.calendar = firstWritable
                print("✅ Using first writable calendar: \(firstWritable.title)")
            } else {
                print("❌ No writable calendar available")
                return false
            }
        }

        do {
            try store.save(event, span: .thisEvent, commit: true)
            print("✅ Event saved successfully to calendar '\(event.calendar?.title ?? "Unknown")'")
            print("   Title: \(title)")
            print("   Start: \(date)")
            print("   End: \(date.addingTimeInterval(durationSeconds))")

            // Verify the event was actually saved
            let savedEvents = store.events(matching: store.predicateForEvents(
                withStart: date.addingTimeInterval(-60),
                end: date.addingTimeInterval(60),
                calendars: nil
            ))

            if savedEvents.contains(where: { $0.title == title }) {
                print("✅ Verified: Event appears in calendar")
            } else {
                print("⚠️ Warning: Event saved but not found in verification")
            }

            return true
        } catch {
            print("❌ Failed to save event: \(error.localizedDescription)")
            print("   Error details: \(error)")
            return false
        }
    }
    
    // Parse natural language date/time using NSDataDetector
    func parseDateTime(from text: String) -> Date? {
        print("🔍 Parsing date from text: '\(text)'")

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        print("🔍 Found \(matches?.count ?? 0) potential date matches")

        // Return the first valid date found
        if let firstMatch = matches?.first, var date = firstMatch.date {
            print("✅ NSDataDetector found raw date: \(date) from text: '\(text)'")

            // If the detected time is midnight (00:00) and text doesn't explicitly say "midnight",
            // default to 9am for better UX
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)

            if components.hour == 0 && components.minute == 0 {
                let lowerText = text.lowercased()
                // Check if user explicitly mentioned a time
                let hasTimeKeyword = lowerText.contains("am") || lowerText.contains("pm") ||
                                      lowerText.contains("midnight") || lowerText.contains("noon") ||
                                      lowerText.contains(":") || lowerText.contains("o'clock")

                if !hasTimeKeyword {
                    // Default to 9am for events without specified time
                    if let adjustedDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) {
                        date = adjustedDate
                        print("⏰ Adjusted time to 9am: \(date)")
                    }
                }
            }

            print("✅ Final parsed date: \(date)")
            return date
        }

        print("❌ NSDataDetector could not find a date in: '\(text)'")
        return nil
    }
}
