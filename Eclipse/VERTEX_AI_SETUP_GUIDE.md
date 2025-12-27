# Vertex AI Imagen Setup Guide

This guide will help you set up Vertex AI for image generation in Eclipse.

## Prerequisites

- Google Cloud account
- Billing enabled on your Google Cloud project
- Access to Google Cloud Console
- gcloud CLI installed (for testing)

## Step 1: Create/Select Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your **Project ID** (you'll need this later)

## Step 2: Enable Vertex AI API

1. In Google Cloud Console, go to **APIs & Services** > **Library**
2. Search for "Vertex AI API"
3. Click **Enable**
4. Search for "Cloud AI Platform" and enable if prompted

## Step 3: Enable Billing

1. Go to **Billing** in Google Cloud Console
2. Link a billing account to your project
3. Imagen 3 pricing: ~$0.04 per image (check latest pricing)

## Step 4: Update GeminiService.swift

Open `GeminiService.swift` and update the following:

```swift
// Line ~17
private let projectId = "YOUR_PROJECT_ID" // Replace with your actual project ID
private let location = "us-central1" // Or your preferred region
```

## Step 5: Authentication Setup

You have 3 options for authentication:

### Option A: Manual Token (For Testing Only)

**Quick but insecure** - Token expires in 1 hour

1. Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)
2. Run: `gcloud auth application-default login`
3. Run: `gcloud auth application-default print-access-token`
4. Copy the token
5. In `GeminiService.swift`, find `getVertexAIAccessToken()` and paste:

```swift
private func getVertexAIAccessToken() async -> String? {
    // TEMPORARY TOKEN - Expires in 1 hour
    return "YOUR_ACCESS_TOKEN_HERE"
}
```

### Option B: Backend Authentication (Recommended)

**Most secure for production**

1. Create a backend server (Node.js, Python, etc.)
2. Store service account credentials on your server
3. Create an endpoint that generates short-lived tokens
4. Update `getVertexAIAccessToken()`:

```swift
private func getVertexAIAccessToken() async -> String? {
    do {
        let url = URL(string: "https://your-backend.com/api/vertex-token")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["token"] as? String
    } catch {
        print("Failed to get token from backend: \(error)")
        return nil
    }
}
```

### Option C: Firebase Auth (If Using Firebase)

**Good balance of security and convenience**

1. Set up Firebase in your project
2. Enable Firebase Authentication
3. Update `getVertexAIAccessToken()`:

```swift
import FirebaseAuth

private func getVertexAIAccessToken() async -> String? {
    do {
        guard let user = Auth.auth().currentUser else {
            print("User not signed in")
            return nil
        }
        return try await user.getIDToken()
    } catch {
        print("Failed to get Firebase token: \(error)")
        return nil
    }
}
```

## Step 6: Test Image Generation

1. Run your app
2. Try generating an image with a prompt like: "generate image of a sunset over mountains"
3. Check the console for detailed logs
4. If you see 403 errors, check your authentication
5. If you see 404 errors, verify your project ID and API is enabled

## Troubleshooting

### Error: 403 Forbidden

**Solution**: Authentication issue
- Check your access token is valid
- Verify you're signed in with correct Google account
- Ensure billing is enabled

### Error: 404 Not Found

**Solution**: Project or API setup issue
- Verify Project ID is correct
- Check Vertex AI API is enabled
- Confirm you're using the correct region

### Error: 400 Bad Request

**Solution**: Request format issue
- Check the prompt isn't empty
- Verify aspectRatio is valid (1:1, 9:16, 16:9, 4:3, 3:4)
- Ensure sampleCount is between 1-4

### Images Not Displaying

**Solution**: Data format issue
- Check console logs for "Successfully decoded image"
- Verify base64 decoding is working
- Check image data size (should be > 0 bytes)

## Testing Checklist

- [ ] Project ID updated in code
- [ ] Vertex AI API enabled
- [ ] Billing enabled
- [ ] Authentication method implemented
- [ ] Generated first test image successfully
- [ ] Console logs show successful requests

## Cost Estimation

**Imagen 3 Pricing** (as of Dec 2024):
- Standard quality: ~$0.04 per image
- Generate 25 images/day = ~$1/day = ~$30/month
- Generate 100 images/day = ~$4/day = ~$120/month

**Tips to reduce costs:**
- Cache generated images
- Implement request limits per user
- Use standard quality instead of HD
- Consider batching requests

## Advanced Configuration

### Changing Image Aspect Ratio

In `generateImage()`, modify the `aspectRatio` parameter:

```swift
"parameters": [
    "aspectRatio": "16:9", // Options: 1:1, 9:16, 16:9, 4:3, 3:4
    // ... other params
]
```

### Adding Negative Prompts

Specify what you DON'T want in the image:

```swift
"parameters": [
    "negativePrompt": "blurry, low quality, watermark, text",
    // ... other params
]
```

### Safety Settings

Control content filtering:

```swift
"parameters": [
    "safetySetting": "block_some", // Options: block_most, block_some, block_few
    // ... other params
]
```

## Production Best Practices

1. **Use Backend Authentication**: Never store credentials in your app
2. **Implement Rate Limiting**: Prevent abuse and control costs
3. **Cache Images**: Store generated images to avoid regenerating
4. **Monitor Usage**: Set up billing alerts in Google Cloud
5. **Handle Errors Gracefully**: Provide user-friendly error messages
6. **Add Loading States**: Image generation takes 3-10 seconds
7. **Image Optimization**: Compress images before saving/displaying

## Resources

- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Imagen API Reference](https://cloud.google.com/vertex-ai/docs/generative-ai/image/generate-images)
- [Pricing Calculator](https://cloud.google.com/products/calculator)
- [Best Practices](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/best-practices)

## Support

If you encounter issues:
1. Check console logs in Xcode
2. Review [Vertex AI quotas](https://cloud.google.com/vertex-ai/docs/quotas)
3. Consult [troubleshooting guide](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/troubleshooting)
4. Contact Google Cloud support if needed

---

**Last Updated**: December 2024
**Compatible with**: iOS 15+, Vertex AI Imagen 3
