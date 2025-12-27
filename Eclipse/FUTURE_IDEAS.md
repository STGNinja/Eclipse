# Eclipse Future Roadmap Proposals

## 🧠 Proactive Intelligence (The "Pro" in Proclipse)

### 1. 🌅 Morning Briefing & Daily Dashboard
*   **Concept**: When opening the app between 6-10 AM, replace the standard chat with a "Daily Briefing" card.
*   **Data Sources**:
    *   **Weather**: "It's raining today, take an umbrella." (Apple Weather)
    *   **Calendar**: "You have 3 meetings, first one at 10 AM." (EventKit)
    *   **Reminders**: "Don't forget to pay rent." (EventKit)
    *   **Health**: "You slept 6 hours. High energy tasks might be harder today." (HealthKit - *New Integration*)
*   **Implementation**: A dynamic, generated summary view that fades into the chat interface.

### 2. 📍 Location Awarereness (Geofencing)
*   **Concept**: "Remind me to buy milk when I'm near grocery store" or "Turn on focus mode when I arrive at the office."
*   **Tech**: CoreLocation with `CLMonitor` for low-power geofencing.
*   **Feature**: AI can set these triggers and notify you via local notifications.

## 🔗 Deep System Integration

### 3. 🍎 Shortcuts App Integration (App Intents)
*   **Concept**: Allow Eclipse to run iOS Shortcuts and vice-versa.
*   **Usage**:
    *   "Hey Siri, ask Eclipse about my schedule."
    *   Eclipse chat: "Run my 'Heading Home' shortcut."
*   **Tech**: `AppIntents` framework.

### 4. ❤️ HealthKit Integration
*   **Concept**: Give Eclipse read-access to Health data (Sleep, Steps, Heart Rate).
*   **Usage**:
    *   "How has my sleep been this week?"
    *   Proactive: "You've been sedentary for 4 hours. Time to stand up!"

### 5. 📱 Interactive Home Screen Widgets
*   **Concept**: A widget that doesn't just show static info but allows quick actions.
*   **Types**:
    *   **"Vision" Widget**: Tap to immediately open the camera for AI analysis.
    *   **"Input" Widget**: Tap to start voice recording or text input immediately.
    *   **"Status" Widget**: Shows the last "Eclipse Insight" or Artifact.

## 🎨 Visual & Experience Polish

### 6. 🌊 Dynamic "Living" Backgrounds
*   **Concept**: The background isn't just a static gradient or image, but reacts to:
    *   **Time of day**: Brighter at noon, deep eclipse colors at night.
    *   **Battery level**: Dims or shifts hue as battery gets low.
    *   **Weather**: Subtle rain/cloud effects using Particle emitters (SpriteKit/SwiftUI).

### 7. 🗣️ "Interruptible" Voice Mode (Gemini Live style)
*   **Concept**: Make the voice chat truly conversational where you can interrupt the AI.
*   **Tech**: Utilizing the new standard for low-latency audio streaming (if API permits) or improving the existing WebRTC implementation.

## 🛠️ Developer Tools (for the User)

### 8. 💻 "Eclipse Code Studio"
*   **Concept**: Expand the `CodeRunnerView` into a mini-IDE.
*   **Features**:
    *   Syntax highlighting for more languages.
    *   Save snippets to a "Code Library" (Artifacts).
    *   Execute Python scripts locally (using a lightweight interpreter).
