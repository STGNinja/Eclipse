# Adobe Photoshop API Setup Guide

## 📋 Overview
This guide will walk you through setting up Adobe's Photoshop API (Firefly Services) to enable AI-powered image editing in Eclipse.

---

## 🎯 Step 1: Create Adobe Developer Account

1. **Go to Adobe Developer Console**
   - Visit: https://developer.adobe.com/console
   - Click **"Sign In"** (top right)

2. **Sign In or Create Account**
   - Use your existing Adobe ID, or
   - Click **"Get an Adobe ID"** to create a free account
   - Complete the registration process

---

## 🔧 Step 2: Create a New Project

1. **Access the Console**
   - Once logged in, you'll see the Adobe Developer Console dashboard
   - Click **"Create new project"** button

2. **Choose Project Type**
   - Select **"Create project from template"**
   - Or click **"Create empty project"** for more control

3. **Name Your Project**
   - Project Name: `Eclipse Photoshop Integration`
   - Description: `AI-powered image editing for Eclipse app`
   - Click **"Create"**

---

## 🔑 Step 3: Add Photoshop API

1. **Add API to Project**
   - In your project dashboard, click **"Add API"**
   - Search for **"Photoshop"** or **"Firefly Services"**
   - Select **"Photoshop API"**
   - Click **"Next"**

2. **Configure API**
   - Choose **"OAuth Server-to-Server"** authentication
   - Click **"Save configured API"**

---

## 🎫 Step 4: Get Your Credentials

1. **Navigate to Credentials**
   - In your project, click on **"Credentials"** in the left sidebar
   - Or click on the **"Photoshop API"** you just added

2. **Copy Your Credentials**
   You'll need these three values:
   
   ```
   Client ID: [Copy this - looks like: a1b2c3d4e5f6g7h8i9j0]
   Client Secret: [Copy this - looks like: p1-A2B3C4D5E6F7G8H9]
   Organization ID: [Copy this - looks like: 1234567890ABCDEF@AdobeOrg]
   ```

3. **Save These Securely**
   - Store them in a password manager
   - You'll add them to your app later

---

## 🔐 Step 5: Generate Access Token

Adobe uses OAuth 2.0, so you need to exchange your credentials for an access token.

### Option A: Using cURL (Quick Test)

```bash
curl -X POST 'https://ims-na1.adobelogin.com/ims/token/v3' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d 'client_id=YOUR_CLIENT_ID' \
  -d 'client_secret=YOUR_CLIENT_SECRET' \
  -d 'scope=openid,AdobeID,firefly_api,ff_apis'
```

### Option B: Using Swift (In Your App)

I'll create a service for this in the next step.

---

## 📝 Step 6: Test API Access

1. **Go to API Reference**
   - Visit: https://developer.adobe.com/firefly-services/docs/photoshop/api/
   - Click **"Try it"** on any endpoint

2. **Test Background Removal**
   - Endpoint: `/pie/psdService/documentOperations`
   - Upload a test image
   - Verify you get a response

---

## ✅ Step 7: Verify Setup

You should now have:
- ✅ Adobe Developer account
- ✅ Project created
- ✅ Photoshop API added
- ✅ Client ID
- ✅ Client Secret
- ✅ Organization ID
- ✅ Tested API access

---

## 🚀 Next Steps

Once you have your credentials, I'll help you:

1. **Create `AdobePhotoshopService.swift`**
   - Handle OAuth authentication
   - Manage access tokens
   - Make API calls

2. **Create `PhotoshopPlugin.swift`**
   - Integrate with Eclipse's plugin system
   - Add AI commands for image editing

3. **Add Image Editing Features**
   - Remove background
   - Apply filters
   - Adjust colors
   - Generative fill
   - And more!

---

## 📚 Useful Links

- **Adobe Developer Console**: https://developer.adobe.com/console
- **Photoshop API Docs**: https://developer.adobe.com/firefly-services/docs/photoshop/
- **API Reference**: https://developer.adobe.com/firefly-services/docs/photoshop/api/
- **Pricing**: https://developer.adobe.com/firefly-services/docs/guides/concepts/pricing/

---

## 💡 Important Notes

### Free Tier
- Adobe offers a **free tier** with limited API calls
- Perfect for development and testing
- Check current limits in the console

### Pricing
- Pay-as-you-go after free tier
- Charges based on:
  - Number of API calls
  - Image size/complexity
  - Processing time

### Rate Limits
- Free tier: ~1,000 calls/month
- Paid tier: Higher limits based on plan
- Check your usage in the console

---

## 🆘 Troubleshooting

### Can't Find Photoshop API?
- Make sure you're looking for **"Firefly Services"**
- Photoshop API is part of Firefly Services

### Authentication Errors?
- Double-check Client ID and Secret
- Ensure you're using the correct scope: `firefly_api,ff_apis`
- Access tokens expire after 24 hours

### API Calls Failing?
- Verify your access token is valid
- Check you haven't exceeded rate limits
- Ensure image format is supported (JPEG, PNG)

---

## ✉️ Ready to Continue?

Once you've completed these steps and have your credentials, let me know and I'll:

1. Create the `AdobePhotoshopService.swift` file
2. Implement OAuth authentication
3. Add image editing capabilities
4. Create the Photoshop plugin
5. Test everything together

**Just say "I have my Adobe credentials" and paste them (or confirm you have them saved), and we'll build the integration!** 🎨
