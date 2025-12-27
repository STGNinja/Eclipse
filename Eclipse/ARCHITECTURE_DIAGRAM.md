# Eclipse Hybrid AI Architecture - Visual Diagram

## System Architecture

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                          USER INTERFACE                        ┃
┃  ┌──────────────────────────────────────────────────────┐     ┃
┃  │  ContentView                                          │     ┃
┃  │  • Message input                                      │     ┃
┃  │  • AI provider indicator (🍎/✨)                      │     ┃
┃  │  • Streaming response display                        │     ┃
┃  └──────────────┬───────────────────────────────────────┘     ┃
┗━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                  │
                  ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                     ROUTING LAYER                              ┃
┃  ┌──────────────────────────────────────────────────────┐     ┃
┃  │  HybridAIRouter (Smart Decision Engine)             │     ┃
┃  │                                                       │     ┃
┃  │  1. Check User Preference                            │     ┃
┃  │     ├─ Automatic (Smart Routing)                     │     ┃
┃  │     ├─ Privacy First (Prefer Apple)                  │     ┃
┃  │     └─ Performance First (Prefer Gemini)             │     ┃
┃  │                                                       │     ┃
┃  │  2. Check Privacy Mode                               │     ┃
┃  │     └─ Enabled → Force Apple Intelligence            │     ┃
┃  │                                                       │     ┃
┃  │  3. Analyze Query                                    │     ┃
┃  │     ├─ Simple?                                       │     ┃
┃  │     ├─ Complex?                                      │     ┃
┃  │     ├─ Sensitive?                                    │     ┃
┃  │     ├─ Real-time data needed?                        │     ┃
┃  │     ├─ Technical depth?                              │     ┃
┃  │     └─ Text editing?                                 │     ┃
┃  │                                                       │     ┃
┃  │  4. Route to Optimal Provider                        │     ┃
┃  └──────────────┬────────────────────┬──────────────────┘     ┃
┗━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━━━━━━━┛
                  │                     │
        ┌─────────┘                     └─────────┐
        │                                         │
        ▼                                         ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━┓     ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  APPLE INTELLIGENCE      ┃     ┃  GOOGLE GEMINI          ┃
┃  ┌────────────────────┐  ┃     ┃  ┌────────────────────┐ ┃
┃  │ AppleIntelligence  │  ┃     ┃  │ GeminiService      │ ┃
┃  │ Service            │  ┃     ┃  │                    │ ┃
┃  │                    │  ┃     ┃  │ • Text Generation  │ ┃
┃  │ • On-Device LLM    │  ┃     ┃  │ • Image Analysis   │ ┃
┃  │ • Private          │  ┃     ┃  │ • Image Generation │ ┃
┃  │ • Free             │  ┃     ┃  │ • Web Search       │ ┃
┃  │ • Fast             │  ┃     ┃  │ • Large Context    │ ┃
┃  │ • 4K context       │  ┃     ┃  │ • 32K+ context     │ ┃
┃  │                    │  ┃     ┃  │                    │ ┃
┃  │ Foundation Models  │  ┃     ┃  │ Gemini 2.5 Flash   │ ┃
┃  │ (iOS 18.1+)        │  ┃     ┃  │ + Imagen 4         │ ┃
┃  └────────────────────┘  ┃     ┃  └────────────────────┘ ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━┛     ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛
        │                                         │
        │                                         │
        └─────────────────┬───────────────────────┘
                          │
                          ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    SUPPORTING SERVICES                         ┃
┃  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────┐ ┃
┃  │ CalendarManager  │  │ WebSearchService │  │ Artifacts   │ ┃
┃  │ • Event access   │  │ • Real-time data │  │ • Personal  │ ┃
┃  │ • Event creation │  │ • Web results    │  │   context   │ ┃
┃  └──────────────────┘  └──────────────────┘  └─────────────┘ ┃
┃                                                                ┃
┃  ┌──────────────────┐  ┌──────────────────┐                  ┃
┃  │ GoogleLiveService│  │ HistoryService   │                  ┃
┃  │ • Voice chat     │  │ • Session save   │                  ┃
┃  │ • Live audio     │  │ • Message history│                  ┃
┃  └──────────────────┘  └──────────────────┘                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## Routing Decision Flow

```
                        ┌───────────────────┐
                        │   User Query      │
                        └─────────┬─────────┘
                                  │
                                  ▼
                        ┌───────────────────┐
                        │ User Preference?  │
                        └─────────┬─────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
      ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
      │  Automatic   │    │Privacy First │    │Performance   │
      │  (Smart)     │    │(Apple pref)  │    │First (Gemini)│
      └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
             │                   │                   │
             │                   └────────┬──────────┘
             │                            │
             ▼                            ▼
    ┌─────────────────┐         ┌─────────────────┐
    │ Analyze Query:  │         │  Route to       │
    │                 │         │  Preferred AI   │
    │ • Simple?       │         │  (if possible)  │
    │ • Complex?      │         └────────┬────────┘
    │ • Sensitive?    │                  │
    │ • Web search?   │                  │
    │ • Images?       │                  │
    │ • Offline?      │                  │
    └────────┬────────┘                  │
             │                            │
             └────────────┬───────────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ Apple            │    │ Google           │
    │ Intelligence     │    │ Gemini           │
    │                  │    │                  │
    │ • Simple queries │    │ • Complex tasks  │
    │ • Private info   │    │ • Images         │
    │ • Text editing   │    │ • Web search     │
    │ • Fast response  │    │ • Advanced AI    │
    └──────────────────┘    └──────────────────┘
```

---

## Query Classification Matrix

```
┌────────────────────────────────────────────────────────────┐
│             QUERY CHARACTERISTICS → AI ROUTING              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  SIMPLE QUERIES                        → Apple 🍎          │
│  ├─ "What's 2+2?"                                          │
│  ├─ "Define photosynthesis"                                │
│  └─ "Explain democracy"                                    │
│                                                             │
│  COMPLEX QUERIES                       → Gemini ✨         │
│  ├─ "Compare quantum vs classical computing"              │
│  ├─ "Analyze the impact of AI on society"                 │
│  └─ "Discuss pros and cons of renewable energy"           │
│                                                             │
│  SENSITIVE INFORMATION                 → Apple 🍎          │
│  ├─ "Help with my health concerns"                         │
│  ├─ "Draft private email"                                  │
│  └─ "Personal financial advice"                            │
│                                                             │
│  REAL-TIME DATA                        → Gemini ✨         │
│  ├─ "Latest news about AI"                                 │
│  ├─ "Current weather forecast"                             │
│  └─ "Recent stock prices"                                  │
│                                                             │
│  TEXT EDITING                          → Apple 🍎          │
│  ├─ "Rewrite this professionally"                          │
│  ├─ "Improve grammar in this text"                         │
│  └─ "Make this more concise"                               │
│                                                             │
│  TECHNICAL/SPECIALIZED                 → Gemini ✨         │
│  ├─ "Write Python code for..."                             │
│  ├─ "Explain quantum entanglement"                         │
│  └─ "Design database schema"                               │
│                                                             │
│  IMAGE ANALYSIS                        → Gemini ✨ (req)   │
│  ├─ [photo] "What's in this image?"                        │
│  └─ [photo] "Describe this scene"                          │
│                                                             │
│  IMAGE GENERATION                      → Gemini ✨ (req)   │
│  ├─ "Generate image of sunset"                             │
│  └─ "Create artwork of mountains"                          │
│                                                             │
│  VOICE CONVERSATIONS                   → Gemini ✨ (req)   │
│  └─ [voice button] Real-time chat                          │
│                                                             │
└────────────────────────────────────────────────────────────┘

Legend:
  🍎 = Apple Intelligence (on-device, private, free)
  ✨ = Google Gemini (cloud, powerful, advanced)
  (req) = Required (no alternative available)
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     USER INTERACTION                          │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
    ┌────────────────────────────────────────┐
    │  1. User types message                 │
    │  2. Optionally attaches image          │
    │  3. Taps send button                   │
    └────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │  ContentView.sendMessage()             │
    │  • Validates input                     │
    │  • Adds to message history             │
    │  • Detects artifacts                   │
    │  • Starts Live Activity                │
    └────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │  processMessage()                      │
    │  • Check for image                     │
    │  • Check for web search need           │
    │  • Check for calendar intent           │
    │  • Gather personal context             │
    └────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │  HybridAIRouter.chat()                 │
    │  • Determine provider                  │
    │  • Analyze query                       │
    │  • Check preferences                   │
    │  • Route to AI service                 │
    └────────────┬───────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
         ▼                ▼
┌────────────────┐  ┌──────────────────┐
│ Apple Intel    │  │ Google Gemini    │
│ Service        │  │ Service          │
│                │  │                  │
│ • Generate     │  │ • Generate       │
│ • Stream       │  │ • Stream         │
│ • Return       │  │ • Return         │
└───────┬────────┘  └──────┬───────────┘
        │                  │
        └────────┬─────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │  Stream to UI                          │
    │  • Update streamingText                │
    │  • Show AI indicator                   │
    │  • Animate response                    │
    └────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │  Complete Response                     │
    │  • Add to messages array               │
    │  • Process calendar events             │
    │  • Save session                        │
    │  • End Live Activity                   │
    └────────────────────────────────────────┘
```

---

## Settings Flow

```
┌─────────────────────────────────────────────────────────┐
│  User opens Settings                                     │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  SettingsView                                            │
│  ┌────────────────────────────────────────────────┐    │
│  │  Profile                                       │    │
│  ├────────────────────────────────────────────────┤    │
│  │  🧠 AI Model (NEW!)                            │◄───┐│
│  │     Automatic (Recommended)               >    │    ││
│  ├────────────────────────────────────────────────┤    ││
│  │  Billing                                       │    ││
│  │  Capabilities                                  │    ││
│  │  ... other settings                            │    ││
│  └────────────────────────────────────────────────┘    ││
└───────────────────────────────────────────────────────────┘│
                    │                                        │
                    ▼                                        │
┌─────────────────────────────────────────────────────────┐ │
│  AISettingsView                                          │ │
│  ┌────────────────────────────────────────────────┐    │ │
│  │  🍎 Apple Intelligence Status                  │    │ │
│  │  ┌──────────────────────────────────────────┐ │    │ │
│  │  │ 🟢 Available                             │ │    │ │
│  │  │ iPhone 15 Pro, iOS 18.1+                 │ │    │ │
│  │  └──────────────────────────────────────────┘ │    │ │
│  ├────────────────────────────────────────────────┤    │ │
│  │  🔒 Privacy Mode                              │    │ │
│  │  [Toggle ON/OFF]                              │    │ │
│  │  Use on-device processing only                │    │ │
│  ├────────────────────────────────────────────────┤    │ │
│  │  🪄 AI Model Preference                       │    │ │
│  │  ○ Automatic (Recommended)          ✓         │    │ │
│  │    Smart routing, best balance                │    │ │
│  │  ○ Privacy First (Apple Intelligence)         │    │ │
│  │    Prefer on-device, fallback to cloud        │    │ │
│  │  ○ Performance First (Google Gemini)          │    │ │
│  │    Always use cloud AI                        │    │ │
│  ├────────────────────────────────────────────────┤    │ │
│  │  💰 Cost Savings                              │    │ │
│  │  On-Device: Free & Private                    │    │ │
│  │  Cloud AI: When Needed                        │    │ │
│  ├────────────────────────────────────────────────┤    │ │
│  │  📊 Feature Comparison                        │    │ │
│  │  Text Generation    🍎 ✓    ✨ ✓             │    │ │
│  │  Image Analysis     🍎 ✗    ✨ ✓             │    │ │
│  │  Image Generation   🍎 ✗    ✨ ✓             │    │ │
│  │  Voice Chat         🍎 ✗    ✨ ✓             │    │ │
│  │  Privacy (On-Device)🍎 ✓    ✨ ✗             │    │ │
│  │  Web Search         🍎 ✗    ✨ ✓             │    │ │
│  └────────────────────────────────────────────────┘    │ │
└──────────────────────────────────────────────────────────┘ │
                                                              │
  User changes preference ─────────────────────────────────┘
  → Immediately affects next query
  → Saved to UserDefaults
  → No restart required
```

---

## Privacy Mode Flow

```
┌────────────────────────────────────────────────────┐
│  User enables Privacy Mode                         │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│  HybridAIRouter.privacyMode = true                 │
│  • Saved to UserDefaults                           │
│  • Takes effect immediately                        │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│  User sends ANY text query                         │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│  Router checks: Privacy Mode enabled?              │
│  YES → Force Apple Intelligence                    │
└──────────────────┬─────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
┌─────────────────┐  ┌─────────────────┐
│ Apple           │  │ Gemini          │
│ Intelligence    │  │ (only if req'd) │
│                 │  │                 │
│ • Text queries  │  │ • Image upload  │
│ • 100% private  │  │ • Image gen     │
│ • On-device     │  │ • Voice chat    │
│ • Fast          │  │                 │
└─────────────────┘  └─────────────────┘
         │                   │
         │                   │
         ▼                   ▼
┌─────────────────────────────────────┐
│ User sees indicator:                 │
│ 🍎 Apple Intelligence (private)     │
│    OR                                │
│ ✨ Gemini (required for images)     │
└─────────────────────────────────────┘
```

---

## Cost Savings Breakdown

```
┌────────────────────────────────────────────────────────────┐
│                    COST ANALYSIS                            │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  WITHOUT HYBRID AI (100% Gemini)                           │
│  ════════════════════════════════════                      │
│                                                             │
│    Simple queries:     1000 × $0.001 = $1.00              │
│    Complex queries:     300 × $0.003 = $0.90              │
│    Image analysis:      100 × $0.002 = $0.20              │
│    ─────────────────────────────────────                   │
│    Total monthly cost:                   $2.10             │
│                                                             │
│  ────────────────────────────────────────────────────      │
│                                                             │
│  WITH HYBRID AI (70% Apple + 30% Gemini)                   │
│  ════════════════════════════════════════                  │
│                                                             │
│    Simple queries:      700 × $0.000 = $0.00 🍎           │
│    (Apple Intelligence)  300 × $0.001 = $0.30 ✨          │
│                                                             │
│    Complex queries:       0 × $0.000 = $0.00 🍎           │
│    (Gemini only)        300 × $0.003 = $0.90 ✨           │
│                                                             │
│    Image analysis:        0 × $0.000 = $0.00 🍎           │
│    (Gemini required)    100 × $0.002 = $0.20 ✨           │
│    ─────────────────────────────────────                   │
│    Total monthly cost:                   $1.40             │
│                                                             │
│  ════════════════════════════════════════                  │
│                                                             │
│    SAVINGS:              $0.70/month (33% reduction)       │
│    ANNUAL SAVINGS:       $8.40/year per user              │
│                                                             │
│    Plus benefits:                                           │
│    ✅ Faster responses (3x for simple queries)            │
│    ✅ Enhanced privacy (70% on-device)                    │
│    ✅ Works offline (Apple Intelligence)                  │
│    ✅ User control (choose preference)                    │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## Error Handling & Fallback

```
┌──────────────────────────────────────────┐
│  Query sent to HybridAIRouter            │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│  Check Apple Intelligence availability   │
└──────────────────┬───────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
┌─────────────────┐  ┌─────────────────┐
│ Available ✓     │  │ Not Available ✗ │
│                 │  │                 │
│ • iPhone 15 Pro │  │ • Older device  │
│ • iOS 18.1+     │  │ • iOS < 18.1    │
│ • Enabled       │  │ • Not enabled   │
└────────┬────────┘  └────────┬────────┘
         │                    │
         │                    ▼
         │         ┌─────────────────────┐
         │         │ Log warning:        │
         │         │ "Apple Intelligence │
         │         │  unavailable,       │
         │         │  using Gemini"      │
         │         └──────────┬──────────┘
         │                    │
         └────────┬───────────┘
                  │
                  ▼
┌──────────────────────────────────────────┐
│  Attempt primary AI (based on routing)   │
└──────────────────┬───────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
┌─────────────────┐  ┌─────────────────┐
│ Success ✓       │  │ Error ✗         │
│                 │  │                 │
│ Return response │  │ • Network error │
│ to user         │  │ • API error     │
└─────────────────┘  │ • Timeout       │
                     └────────┬────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │ Try fallback AI     │
                   │ (if applicable)     │
                   └──────────┬──────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
           ┌─────────────────┐  ┌─────────────────┐
           │ Success ✓       │  │ Final Error ✗   │
           │                 │  │                 │
           │ Return response │  │ Show error msg  │
           │ to user         │  │ to user         │
           └─────────────────┘  └─────────────────┘
```

---

**This architecture ensures robust, intelligent, and privacy-focused AI routing! 🚀**
