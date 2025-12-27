# Image Specifications for Eclipse App

## Required Images

### 1. betterlunr.png (Greeting Logo)
**Purpose:** Displays on the welcome/greeting screen  
**Name in Assets:** `betterlunr` (all lowercase)  
**Recommended Size:** 
- Minimum: 300x300 pixels
- Recommended: 512x512 pixels or larger
- Format: PNG with transparent background (optional)

**Where to add:**
```
Assets.xcassets → + → New Image Set → Name: "betterlunr"
```

### 2. BETTERLUNR.png (App Icon)
**Purpose:** App icon shown on home screen  
**Name in Assets:** `AppIcon` (default iOS app icon)  
**Required Sizes for iOS:**
- 1024x1024 pixels (App Store)
- Various smaller sizes (Xcode generates these)

**Where to add:**
```
Assets.xcassets → AppIcon → Drag image into slots
```

## Quick Add Steps

### For betterlunr.png:
1. Open Xcode project
2. Click on `Assets.xcassets` in Project Navigator (left sidebar)
3. Click `+` at the bottom left
4. Select "New Image Set"
5. Name it: `betterlunr` (must match exactly)
6. Drag your `betterlunr.png` file into any of the boxes (1x, 2x, or 3x)
7. Done! The image will now work in the app

### For BETTERLUNR.png (App Icon):
1. Open Xcode project
2. Click on `Assets.xcassets` in Project Navigator
3. Click on `AppIcon` in the list
4. Drag your `BETTERLUNR.png` into the "1024x1024" box at minimum
5. Optional: Drag into other sizes or let Xcode generate them
6. Done! Your app icon is set

## Tips

- **Square Images Work Best:** Both images should be square (same width and height)
- **PNG Format:** Use PNG for best quality and transparency support
- **High Resolution:** Use high-res images, iOS will scale them down as needed
- **Transparent Background:** For the greeting logo, transparent background looks better

## If You Don't Have Images Yet

You can:
1. Use the app with the placeholder (SF Symbol) temporarily
2. Create simple icons using Preview or any design tool
3. Use an AI image generator (like DALL-E, Midjourney, Stable Diffusion)
4. Design in Figma, Sketch, or Canva
5. Hire a designer on Fiverr or similar platform

## Testing Without Images

The app will still work without these images:
- A system icon will show instead of betterlunr.png
- Default iOS icon will show instead of app icon

But it's recommended to add them for the full experience!

## File Checklist

- [ ] betterlunr.png created
- [ ] betterlunr.png added to Assets.xcassets
- [ ] BETTERLUNR.png created
- [ ] BETTERLUNR.png added to AppIcon in Assets.xcassets
- [ ] Tested app with images loaded
- [ ] App icon shows on home screen

---

Happy building! 🚀
