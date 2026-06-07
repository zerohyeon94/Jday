# Jday App Store Screenshots

Generated from the raw captures in `Screenshots/iOS`, `Screenshots/iPadOS`, and `Screenshots/macOS`.

## Upload Files

### iOS

Use the PNG files in `Screenshots/AppStore/iOS`.

- Size: `1290 x 2796`
- Source: iPhone simulator captures
- Style: App Store marketing frame with headline and device mockup

### iPadOS

Use the PNG files in `Screenshots/AppStore/iPadOS`.

- Size: `2752 x 2064`
- Source: iPadOS simulator captures
- Style: App Store marketing frame with headline and large iPad screen mockup

### macOS

Use the PNG files in `Screenshots/AppStore/macOS`.

- Size: `2880 x 1800`
- Aspect ratio: `16:10`
- Source: macOS app captures with black outer background cropped
- Style: App Store marketing frame with headline and large Mac app window

## Regenerate

```bash
python3 Screenshots/generate_app_store_images.py
```

The generated files overwrite the current outputs but do not modify the raw captures.
