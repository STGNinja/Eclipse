# Eclipse Hybrid AI - Testing Guide

## Quick Testing Scenarios

### ✅ Test 1: Simple Query (Should use Apple Intelligence)
**Query:** "What's 2+2?"

**Expected Result:**
- Fast response: "4"
- Top bar shows Apple logo 
- Privacy-focused, on-device processing

**Why Apple Intelligence?**
- Very simple calculation
- Short query (3 words)
- No web search needed
- No complex reasoning required

---

### ✅ Test 2: Explain Query (Should use Apple Intelligence)
**Query:** "Explain what photosynthesis is"

**Expected Result:**
- Clear, concise explanation
- Top bar shows Apple logo
- Quick response time

**Why Apple Intelligence?**
- Simple explanation request
- General knowledge (no web search needed)
- Under 50 words
- Straightforward question format

---

### ✅ Test 3: Complex Reasoning (Should use Gemini)
**Query:** "Compare and contrast the advantages and disadvantages of quantum computing versus classical computing, explain the technical challenges in building quantum computers, and discuss potential applications in cryptography"

**Expected Result:**
- Detailed, comprehensive response
- Top bar shows Gemini sparkles ✨
- Longer response time (but more detailed)

**Why Gemini?**
- Very long query (30+ words)
- Multiple complex questions
- Requires multi-step reasoning
- "Compare and contrast" indicator
- Technical depth required

---

### ✅ Test 4: Real-Time Information (Should use Gemini)
**Query:** "What's the latest news about AI developments?"

**Expected Result:**
- Web search indicator appears briefly
- Current, up-to-date information
- Top bar shows Gemini sparkles ✨
- Multiple sources cited

**Why Gemini?**
- Contains "latest" keyword (real-time data needed)
- Requires web search
- Current events information
- Apple Intelligence doesn't have internet access

---

### ✅ Test 5: Sensitive Information (Should use Apple Intelligence)
**Query:** "Help me draft a private email about my health concerns"

**Expected Result:**
- On-device processing
- Top bar shows Apple logo 
- Privacy-maintained
- Helpful draft provided

**Why Apple Intelligence?**
- Contains "health" keyword (sensitive)
- Contains "private" keyword
- Personal medical information
- Privacy-critical content

---

### ✅ Test 6: Image Analysis (Must use Gemini)
**Steps:**
1. Tap camera/photo button
2. Select an image (e.g., photo of a dog)
3. Type: "What's in this image?"

**Expected Result:**
- Image analyzing indicator appears
- Detailed image description
- Top bar shows Gemini sparkles ✨
- Identifies objects, colors, composition

**Why Gemini?**
- Apple Intelligence doesn't support image input yet
- Only Gemini has multimodal capabilities
- No alternative available

---

### ✅ Test 7: Image Generation (Must use Gemini)
**Query:** "Generate an image of a sunset over mountains"

**Expected Result:**
- Image generation indicator appears
- Beautiful generated image
- Top bar shows Gemini sparkles ✨
- Uses Imagen 4 model

**Why Gemini?**
- Only Gemini has image generation (Imagen 4)
- Apple Intelligence Image Playground API not available yet
- Required feature

---

### ✅ Test 8: Privacy Mode Enabled
**Steps:**
1. Open Settings > AI Model
2. Enable Privacy Mode toggle
3. Send query: "What is machine learning?"

**Expected Result:**
- Apple Intelligence used (if available)
- Top bar shows Apple logo 
- Privacy Mode active indicator
- 100% on-device processing

**Why Apple Intelligence?**
- Privacy Mode forces on-device processing
- Only falls back to Gemini for impossible tasks (images)
- User explicitly chose privacy

---

### ✅ Test 9: Text Rewriting (Should use Apple Intelligence)
**Query:** "Rewrite this in a professional tone: hey boss, i think we should maybe look at that thing we talked about"

**Expected Result:**
- Professionally rewritten text
- Top bar shows Apple logo 
- Quick response
- Improved grammar and tone

**Why Apple Intelligence?**
- "Rewrite" keyword (text editing intent)
- Simple transformation task
- No external data needed
- Apple Intelligence excels at text manipulation

---

### ✅ Test 10: Calendar Query (Uses current system)
**Query:** "What's on my calendar today?"

**Expected Result:**
- Calendar access indicator appears
- Lists upcoming events
- Uses whichever AI is appropriate
- Calendar events included in context

**Why Mixed?**
- Simple calendar query → Apple Intelligence
- But uses existing calendar integration
- Routing happens after calendar data fetched

---

### ✅ Test 11: Web Search + Complex (Should use Gemini)
**Query:** "Search for recent research papers on neural networks and summarize the key findings"

**Expected Result:**
- Web search indicator appears
- Gemini sparkles in top bar ✨
- Comprehensive summary with sources
- Up-to-date research findings

**Why Gemini?**
- Requires web search ("search for")
- Real-time information needed ("recent")
- Complex summarization task
- Multiple sources needed

---

### ✅ Test 12: Voice Conversation (Always Gemini Live)
**Steps:**
1. Tap voice button (waveform icon)
2. Speak: "Tell me about quantum physics"
3. Listen to response

**Expected Result:**
- Voice sheet opens
- Real-time voice conversation
- Gemini Live handles audio
- Natural back-and-forth dialogue

**Why Gemini?**
- Only Gemini has Live API for voice
- Real-time audio streaming required
- Apple Intelligence doesn't have voice API yet
- Voice features untouched from before

---

## Testing AI Preference Settings

### Test: Automatic Mode (Default)
**Settings:** Settings > AI Model > Automatic (Recommended)

**Expected Behavior:**
- Simple queries → Apple Intelligence
- Complex queries → Gemini
- Smart routing based on query type
- Optimal cost/performance balance

**Test Queries:**
- "What's the capital of France?" → Apple 
- "Explain quantum entanglement in detail" → Gemini ✨

---

### Test: Privacy First Mode
**Settings:** Settings > AI Model > Privacy First (Apple Intelligence)

**Expected Behavior:**
- Almost all queries → Apple Intelligence
- Only uses Gemini when absolutely required (images)
- Maximizes on-device processing
- Privacy indicator visible

**Test Queries:**
- "What's 2+2?" → Apple 
- "Explain machine learning" → Apple 
- [Image upload] → Gemini ✨ (required)

---

### Test: Performance First Mode
**Settings:** Settings > AI Model > Performance First (Google Gemini)

**Expected Behavior:**
- All queries → Gemini
- Maximum capabilities
- No on-device processing attempts
- Always shows Gemini sparkles ✨

**Test Queries:**
- "What's 2+2?" → Gemini ✨
- "Explain machine learning" → Gemini ✨
- Complex reasoning → Gemini ✨

---

## Device Compatibility Tests

### Test: iPhone 15 Pro with iOS 18.1+
**Expected:**
- Apple Intelligence available ✅
- Settings show "Available" status
- Privacy Mode can be enabled
- Hybrid routing works perfectly

### Test: iPhone 14 Pro with iOS 18.1+
**Expected:**
- Apple Intelligence NOT available ❌
- Settings show "Device not eligible" message
- Privacy Mode toggle disabled
- All queries gracefully fall back to Gemini
- Zero functionality loss

### Test: iPhone 15 Pro with iOS 17.x
**Expected:**
- Apple Intelligence NOT available ❌
- Settings show "iOS 18.1+ required" message
- Automatic fallback to Gemini
- User notified to update iOS

---

## Indicator Verification

### Top Bar Indicators:
**Apple Intelligence:**
- Icon: Apple logo 
- Text: "Apple Intelligence"
- Color: White/subtle

**Google Gemini:**
- Icon: Sparkles ✨
- Text: "Google Gemini"
- Color: White/subtle

**Verify:**
- Indicator appears during streaming
- Updates in real-time
- Matches actual AI used
- Clears between queries

---

## Settings UI Tests

### Test: Open AI Settings
**Steps:**
1. Open Settings (gear icon)
2. Tap "AI Model" row (purple brain icon)
3. Verify comprehensive settings view opens

**Expected:**
- Apple Intelligence status card
- Privacy Mode toggle
- AI Preference selector (3 options)
- Cost savings information
- Feature comparison table

### Test: Apple Intelligence Status
**Check:**
- Green circle + "Available" (if eligible)
- Red circle + explanation (if not)
- Real-time status updates
- Clear messaging

### Test: Privacy Mode Toggle
**When Available:**
- Toggle enabled
- Can switch on/off
- Immediate effect on routing
- Haptic feedback on change

**When Unavailable:**
- Toggle disabled
- Orange warning message
- Clear explanation why

### Test: AI Preference Selection
**Verify:**
- 3 options visible
- Current selection highlighted (purple checkmark)
- Descriptions shown for each
- Tap changes preference immediately
- Haptic feedback on selection

---

## Performance Benchmarks

### Response Time Comparison:

| Query Type        | Apple Intelligence | Google Gemini |
|-------------------|-------------------|---------------|
| Simple (2+2)      | ~0.5s            | ~1.5s         |
| Explanation       | ~1.5s            | ~2.5s         |
| Complex reasoning | N/A              | ~5-8s         |
| Image analysis    | N/A              | ~3-5s         |

**Note:** Apple Intelligence is typically faster for simple queries due to on-device processing (no network latency).

---

## Error Handling Tests

### Test: Apple Intelligence Unavailable
**Scenario:** User on iPhone 14, tries to enable Privacy Mode

**Expected:**
- Toggle remains disabled
- Orange warning message displayed
- App continues working with Gemini
- No crashes or errors

### Test: Network Offline
**Scenario:** Turn on Airplane Mode, send query

**Expected:**
- If Apple Intelligence available: Works perfectly ✅
- If not available: Clear error message about network
- No silent failures
- Helpful user guidance

### Test: Model Not Ready
**Scenario:** Apple Intelligence downloading on first setup

**Expected:**
- Status shows "Model Not Ready"
- Clear message: "downloading or not ready"
- Automatic fallback to Gemini
- Retry prompt after download complete

---

## Console Log Verification

Look for these console messages:

### Apple Intelligence:
```
✅ Apple Intelligence is available
🤖 Using Apple Intelligence for query
✅ Apple Intelligence stream completed
```

### Gemini:
```
🤖 Using Google Gemini for query
🚀 Sending request to: [Gemini API URL]
✅ Connection successful, parsing response...
✅ Stream completed
```

### Routing Decisions:
```
⚠️ Privacy mode enabled but Apple Intelligence unavailable, using Gemini
⚠️ Apple Intelligence preferred but not available for this request, using Gemini
```

---

## Success Criteria Checklist

- [ ] Simple queries use Apple Intelligence (when available)
- [ ] Complex queries use Gemini
- [ ] Image features always use Gemini
- [ ] Privacy Mode forces on-device processing
- [ ] Voice conversations work unchanged (Gemini Live)
- [ ] Graceful fallback on unsupported devices
- [ ] No crashes or errors on any device
- [ ] Settings UI shows correct status
- [ ] Top bar indicators update correctly
- [ ] All existing features still work
- [ ] Calendar integration intact
- [ ] Web search integration intact
- [ ] Message history preserved
- [ ] Session saving works
- [ ] No performance regressions

---

## Quick Test Script

**Run these 5 queries in order:**

1. "What's 2+2?" → Should see Apple logo 
2. "Explain quantum computing in detail" → Should see Gemini ✨
3. "Draft a private email" → Should see Apple logo 
4. [Upload photo] "Describe this" → Should see Gemini ✨
5. Enable Privacy Mode → Send "Hello" → Should see Apple logo 

**All 5 working?** ✅ Hybrid AI is functioning perfectly!

---

**Happy Testing! 🧪**
