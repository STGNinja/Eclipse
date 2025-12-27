# Gemini Live API Setup Fix

## Problem
The connection was successful, but the setup message was rejected with:
```
Invalid JSON payload received. Unknown name "inputAudioFormat" at 'setup': Cannot find field.
```

## Root Cause
The setup message format was incorrect. The Gemini Live API:
1. **Does NOT accept `inputAudioFormat` in the setup message**
2. Audio format is specified in the MIME type when sending each audio chunk
3. The API version path was incorrect (`v1beta` should be `v1alpha`)
4. The model name format was non-standard

## Fixed Configuration

### 1. Correct API Endpoint
```swift
private let path = "/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"
```
Changed from `v1beta` to `v1alpha` (the Live API is in alpha)

### 2. Correct Model Name
```swift
private let modelName = "models/gemini-2.0-flash-exp"
```
Changed from `models/gemini-2.5-flash-native-audio-preview-12-2025` to a standard model identifier

### 3. Simplified Setup Message
```swift
let setupJSON: [String: Any] = [
    "setup": [
        "model": modelName,
        "generationConfig": [
            "responseModalities": ["AUDIO"]
        ]
    ]
]
```

**Removed:**
- `inputAudioFormat` - Not part of the setup schema
- `tools` - Optional, can be added later if needed
- `speechConfig` - Using default voice is fine

### 4. Audio Format in realtime chunks
Audio format is specified when sending each chunk:
```swift
let msg: [String: Any] = [
    "realtimeInput": [
        "mediaChunks": [
            [
                "mimeType": "audio/pcm;rate=\(sampleRate)",
                "data": audioData.base64EncodedString()
            ]
        ]
    ]
]
```

## Gemini Live API Structure

### Setup Message (Initial Connection)
```json
{
  "setup": {
    "model": "models/gemini-2.0-flash-exp",
    "generationConfig": {
      "responseModalities": ["AUDIO"]
    }
  }
}
```

### Setup Response
```json
{
  "setupComplete": {}
}
```

### Sending Audio Input
```json
{
  "realtimeInput": {
    "mediaChunks": [
      {
        "mimeType": "audio/pcm;rate=16000",
        "data": "<base64_encoded_audio>"
      }
    ]
  }
}
```

### Receiving Audio Output
```json
{
  "serverContent": {
    "modelTurn": {
      "parts": [
        {
          "inlineData": {
            "mimeType": "audio/pcm",
            "data": "<base64_encoded_audio>"
          }
        }
      ]
    }
  }
}
```

## Testing

After applying these fixes, you should see:
```
🚀 [Native] Connecting to Gemini Live API...
✅ [Native] WebSocket Opened Successfully
✅ [Native] Connection Established
📤 [Native] Sending setup: [setup: [...]]
✅ [Native] Setup complete, starting audio capture
```

## References

- [Gemini API Documentation](https://ai.google.dev/api)
- [Multimodal Live API](https://ai.google.dev/api/multimodal-live)
- API uses `v1alpha` for the Live API endpoint
- Audio format is sent per-chunk, not in setup
