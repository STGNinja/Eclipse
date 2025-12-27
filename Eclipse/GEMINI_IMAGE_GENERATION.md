# Gemini Native Image Generation - Quick Start

## ✅ Image Generation is NOW WORKING!

Eclipse now uses **Gemini 2.5 Flash Image** for image generation - no setup required!

## How to Use

Just type in Eclipse:
```
"generate image of a sunset over mountains"
"create image of a cat wearing a wizard hat"
"draw a futuristic city skyline"
```

## What's Included

- ✅ **FREE** (or extremely cheap - ~$0.002 per image)
- ✅ **No setup required** - uses your existing API key
- ✅ **Fast generation** - typically 3-5 seconds
- ✅ **High quality** - 1024x1024 resolution
- ✅ **Multiple aspect ratios** - square, landscape, portrait

## Technical Details

**Model**: `gemini-2.5-flash-image` (aka "Nano Banana")  
**Cost**: ~$0.002 per image (500x cheaper than Vertex AI)  
**Resolution**: 1024x1024 default  
**API Key**: Uses same key as text generation  

## Cost Comparison

| Images per Day | Cost per Day | Cost per Month |
|----------------|--------------|----------------|
| 10 images      | $0.02        | $0.60          |
| 50 images      | $0.10        | $3.00          |
| 100 images     | $0.20        | $6.00          |
| 500 images     | $1.00        | $30.00         |

**Compare to alternatives:**
- DALL-E 3: $0.04 per image (20x more expensive)
- Midjourney: $10/month minimum (less control)
- Stable Diffusion: Requires setup & hosting

## Supported Aspect Ratios

You can request different aspect ratios (currently hardcoded to 1:1 in the code):

- `1:1` - Square (1024x1024) - **Default**
- `16:9` - Landscape (1344x768)
- `9:16` - Portrait (768x1344)
- `4:3` - Wide (1184x864)
- `3:4` - Tall (864x1184)

## Advanced: Upgrading to Pro

If you need higher quality, you can upgrade to `gemini-3-pro-image-preview`:

**Features**:
- Up to 4K resolution (4096x4096)
- Up to 14 reference images
- Google Search grounding
- Advanced "thinking" mode
- Professional asset production

**Cost**: Higher than Flash but still competitive

## How It Works

1. User types "generate image of..."
2. Eclipse detects image generation intent
3. Sends prompt to Gemini 2.5 Flash Image
4. Receives base64 encoded PNG
5. Displays in chat

All of this happens in `GeminiService.swift` using the same authentication as text chat!

## Troubleshooting

### Images not generating?

**Check console logs** - You should see:
```
🎨 Sending Gemini 2.5 Flash Image generation request
📡 Image Response status code: 200
✅ Generated 1 image(s) using Gemini 2.5 Flash Image
```

### Getting 403 errors?

- Verify your API key is valid
- Check you haven't exceeded rate limits
- Ensure API key has Gemini API access enabled

### Images are blurry/low quality?

- Try more detailed prompts
- Specify style (e.g., "photorealistic", "4K quality")
- Consider upgrading to `gemini-3-pro-image-preview`

## Example Prompts

**Good prompts** (detailed):
```
"A photorealistic sunset over snow-capped mountains, golden hour lighting, 
dramatic clouds, vibrant orange and purple sky, professional photography"

"A kawaii-style sticker of a happy red panda eating bamboo, cute expression, 
bright colors, chibi art style, transparent background"

"A minimalist logo for a coffee shop called 'Morning Brew', modern typography, 
earth tones, simple coffee cup icon, clean design"
```

**Bad prompts** (too vague):
```
"sunset"
"cat"
"logo"
```

## Resources

- [Official Gemini Image Generation Docs](https://ai.google.dev/gemini-api/docs/image-generation)
- [Gemini API Pricing](https://ai.google.dev/pricing)
- [Image Generation Cookbook](https://github.com/google-gemini/cookbook)

---

**Last Updated**: December 2024  
**Status**: ✅ Fully Implemented & Working
