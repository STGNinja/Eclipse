# Gemini Live WebSocket Connection Fix

## Problem
The Gemini Live API was failing with the following errors:
```
nw_flow_add_write_request [C4] cannot accept write requests
nw_write_request_report [C4] Send failed with error "Socket is not connected"
❌ [Native] Receive Error: The operation couldn't be completed. Socket is not connected
```

## Root Causes

1. **Race Condition**: The code was trying to send setup messages immediately after calling `resume()` on the WebSocket, before the TCP/TLS handshake completed
2. **No Connection State Validation**: Messages were being sent without verifying the WebSocket was in a `.running` state
3. **Basic URLSession Configuration**: Using `.default` configuration without proper timeouts or delegate
4. **Missing Delegate Implementation**: No URLSessionWebSocketDelegate to track connection lifecycle
5. **Insufficient Error Handling**: Not checking specific error codes or WebSocket state

## Solutions Applied

### 1. Proper URLSession Configuration
```swift
private func setupURLSession() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300
    config.waitsForConnectivity = true
    urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
}
```

### 2. Connection Task with Handshake Wait
```swift
connectionTask = Task { @MainActor in
    self.webSocketTask?.resume()
    
    // Give the WebSocket time to complete the handshake
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    // Verify connection state
    guard let task = self.webSocketTask, task.state == .running else {
        self.handleError("WebSocket failed to establish connection")
        return
    }
    
    self.isConnected = true
    self.receiveMessage()
    self.sendSetupMessage()
}
```

### 3. State Validation in Send Method
```swift
// Check connection state before sending
guard isConnected, let task = webSocketTask, task.state == .running else {
    print("⚠️ [Native] Cannot send - WebSocket not in running state")
    return
}
```

### 4. URLSessionWebSocketDelegate Implementation
```swift
extension GoogleLiveService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, 
                   didOpenWithProtocol protocol: String?) {
        print("✅ [Native] WebSocket Opened Successfully")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, 
                   didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // Handle closure gracefully
    }
}
```

### 5. Enhanced Error Handling
- Check for specific error codes (57 = Socket not connected, 54 = Connection reset)
- Verify WebSocket state before operations
- Automatic disconnect on connection errors
- Better logging with error codes and domains

## Testing
After applying these fixes:
1. The WebSocket should complete its handshake before any messages are sent
2. Connection state is validated before all send/receive operations
3. Proper delegate callbacks confirm connection establishment
4. Error handling gracefully manages connection failures

## Expected Behavior
```
🚀 [Native] Connecting to Gemini Live API...
✅ [Native] WebSocket Opened Successfully
✅ [Native] Connection Established
✅ [Native] Setup complete, starting audio capture
```
