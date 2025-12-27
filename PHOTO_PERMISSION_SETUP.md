# Photo Library Permission Setup

To enable saving images to the photo library, you need to add the following key to your `Info.plist` file:

## Required Permission Key

Add this to your Info.plist:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Eclipse needs access to save generated images to your photo library.</string>
```

## How to Add in Xcode

1. Open your project in Xcode
2. Select the Eclipse target
3. Go to the "Info" tab
4. Click the "+" button to add a new key
5. Select "Privacy - Photo Library Additions Usage Description"
6. Enter the description: "Eclipse needs access to save generated images to your photo library."

This permission allows the app to save images without requesting full photo library access.
