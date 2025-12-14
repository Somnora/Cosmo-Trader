# Cosmo Trader - Screenshot Requirements

## App Store Connect Screenshot Requirements (2024)

App Store Connect requires screenshots for specific device sizes. You must provide at least one set, but providing all sizes ensures optimal display across devices.

---

## Required Screenshots by Device

### iPhone (Required)

#### 6.7" Display (iPhone 15 Pro Max, 14 Pro Max, etc.)
| Specification | Value |
|---------------|-------|
| **Resolution** | 1290 x 2796 pixels |
| **Orientation** | Portrait (recommended) or Landscape |
| **Format** | PNG or JPEG |
| **Color Space** | sRGB or P3 |
| **Minimum** | 3 screenshots |
| **Maximum** | 10 screenshots |

**Devices:** iPhone 15 Pro Max, iPhone 15 Plus, iPhone 14 Pro Max, iPhone 14 Plus

#### 6.5" Display (iPhone 11 Pro Max, XS Max, etc.)
| Specification | Value |
|---------------|-------|
| **Resolution** | 1284 x 2778 pixels |
| **Orientation** | Portrait (recommended) or Landscape |
| **Format** | PNG or JPEG |
| **Color Space** | sRGB or P3 |
| **Minimum** | 3 screenshots |
| **Maximum** | 10 screenshots |

**Devices:** iPhone 11 Pro Max, iPhone XS Max

#### 6.1" Display (iPhone 15 Pro, 14 Pro, etc.)
| Specification | Value |
|---------------|-------|
| **Resolution** | 1179 x 2556 pixels |
| **Orientation** | Portrait (recommended) or Landscape |
| **Format** | PNG or JPEG |
| **Optional** | Can use 6.7" screenshots (will scale) |

**Devices:** iPhone 15 Pro, iPhone 14 Pro

#### 5.5" Display (iPhone 8 Plus, 7 Plus, etc.)
| Specification | Value |
|---------------|-------|
| **Resolution** | 1242 x 2208 pixels |
| **Orientation** | Portrait (recommended) or Landscape |
| **Format** | PNG or JPEG |
| **Color Space** | sRGB |
| **Minimum** | 3 screenshots |
| **Maximum** | 10 screenshots |

**Devices:** iPhone 8 Plus, iPhone 7 Plus, iPhone 6s Plus

---

### iPad (Optional but Recommended)

#### 12.9" Display (iPad Pro 6th gen)
| Specification | Value |
|---------------|-------|
| **Resolution** | 2048 x 2732 pixels |
| **Orientation** | Portrait or Landscape |
| **Format** | PNG or JPEG |
| **Minimum** | 3 screenshots |
| **Maximum** | 10 screenshots |

**Devices:** iPad Pro 12.9" (6th, 5th, 4th, 3rd generation)

#### 11" Display (iPad Pro, iPad Air)
| Specification | Value |
|---------------|-------|
| **Resolution** | 1668 x 2388 pixels |
| **Orientation** | Portrait or Landscape |
| **Format** | PNG or JPEG |
| **Optional** | Can use 12.9" screenshots (will scale) |

**Devices:** iPad Pro 11", iPad Air (5th, 4th generation)

---

## Screenshot Checklist for Cosmo Trader

### Recommended Screenshot Sequence (6-7 screenshots)

| # | Screen | Description | Key Elements |
|---|--------|-------------|--------------|
| 1 | **Portfolio View** | Main portfolio with holdings | Stock list, total value, daily change, cosmic theme |
| 2 | **Stock Detail** | Individual stock with compatibility | Price, chart, zodiac score, cosmic insights |
| 3 | **Discover** | Swipe cards interface | Stock card, compatibility %, pass/add buttons |
| 4 | **Horoscope** | Daily cosmic horoscope | Personalized reading, zodiac sign, date |
| 5 | **Moon Phase** | Moon phase calendar | Current phase, VOC indicator, lunar calendar |
| 6 | **Profile** | User profile with zodiac | Birth chart, stats, zodiac wheel |
| 7 | **Paywall** | Oracle tier upgrade | Premium features, pricing, benefits |

---

## Screenshot Design Guidelines

### Visual Requirements
- **Status Bar**: Include or hide consistently
- **Home Indicator**: Include (shows real device context)
- **Time**: Use 9:41 AM (Apple's traditional screenshot time)
- **Battery**: Full or charging indicator
- **Carrier**: "Cosmo" or blank (not "Carrier")

### Content Guidelines
- Show real, compelling data (not placeholder text)
- Use attractive stock performances (mix of gains/losses)
- Ensure text is readable at thumbnail size
- Highlight unique features (zodiac scores, cosmic theme)
- Avoid sensitive information (real account data)

### Design Tips
- Consider device frames (mockups showing iPhone)
- Add marketing text overlays (optional)
- Keep text minimal — visuals should speak
- Use consistent background color/gradient
- Show dark mode (app's primary theme)

---

## File Naming Convention

```
CosmoTrader_[Device]_[Number]_[Screen].png
```

Examples:
```
CosmoTrader_iPhone67_01_Portfolio.png
CosmoTrader_iPhone67_02_StockDetail.png
CosmoTrader_iPhone67_03_Discover.png
CosmoTrader_iPhone67_04_Horoscope.png
CosmoTrader_iPhone67_05_MoonPhase.png
CosmoTrader_iPhone67_06_Profile.png
CosmoTrader_iPhone55_01_Portfolio.png
```

---

## Screenshot Capture Methods

### Method 1: Simulator (Recommended for Clean Shots)
```bash
# Open Simulator
xcrun simctl list devices

# Take screenshot
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Or use Cmd+S in Simulator
```

### Method 2: Physical Device
1. Press **Side Button + Volume Up** simultaneously
2. Screenshot saves to Photos
3. AirDrop to Mac for editing

### Method 3: Xcode Instruments
1. Window > Devices and Simulators
2. Select device
3. Take Screenshot button

---

## App Preview Video (Optional)

### Specifications
| Device | Resolution | Duration |
|--------|------------|----------|
| iPhone 6.7" | 1290 x 2796 | 15-30 sec |
| iPhone 6.5" | 1284 x 2778 | 15-30 sec |
| iPhone 5.5" | 1242 x 2208 | 15-30 sec |
| iPad 12.9" | 2048 x 2732 | 15-30 sec |

### Video Guidelines
- Format: H.264, M4V, MP4, MOV
- Frame rate: 30 fps
- Audio: Optional (AAC, 256 kbps)
- First frame should be compelling (used as poster)
- Show app in action — scrolling, tapping, swiping

### Suggested Video Flow (30 sec)
1. 0-5s: App launch, portfolio overview
2. 5-10s: Scroll through holdings, show compatibility
3. 10-15s: Navigate to Discover, swipe through stocks
4. 15-20s: View daily horoscope
5. 20-25s: Check moon phase
6. 25-30s: Return to portfolio, end card with logo

---

## Quick Reference: All Sizes

| Device Class | Resolution | Required |
|--------------|------------|----------|
| iPhone 6.7" | 1290 x 2796 | ✓ Yes |
| iPhone 6.5" | 1284 x 2778 | ✓ Yes |
| iPhone 6.1" Pro | 1179 x 2556 | Optional (scales from 6.7") |
| iPhone 5.5" | 1242 x 2208 | ✓ Yes |
| iPad 12.9" | 2048 x 2732 | Recommended |
| iPad 11" | 1668 x 2388 | Optional (scales from 12.9") |

---

## Screenshot Production Workflow

### Phase 1: Preparation
- [ ] Set up demo account with good sample data
- [ ] Add stocks with mix of gains/losses
- [ ] Set zodiac sign that has good compatibility visuals
- [ ] Ensure app is in dark mode

### Phase 2: Capture
- [ ] Capture all screens on 6.7" simulator
- [ ] Capture all screens on 5.5" simulator (or scale)
- [ ] Review for any cut-off text or visual issues
- [ ] Ensure consistency across all screenshots

### Phase 3: Enhancement (Optional)
- [ ] Add device frames if desired
- [ ] Add marketing headlines
- [ ] Apply consistent treatment to all images
- [ ] Optimize file sizes (under 500KB ideal)

### Phase 4: Upload
- [ ] Name files according to convention
- [ ] Upload to App Store Connect in order
- [ ] Preview in all device sizes
- [ ] Check thumbnail appearance

---

## Marketing Text Overlay Suggestions

If adding text overlays to screenshots:

| Screenshot | Headline |
|------------|----------|
| Portfolio | "Track Your Cosmic Portfolio" |
| Stock Detail | "Zodiac-Powered Insights" |
| Discover | "Swipe for Stock Compatibility" |
| Horoscope | "Daily Trading Horoscopes" |
| Moon Phase | "Lunar Market Cycles" |
| Profile | "Your Astrological Profile" |
| Paywall | "Unlock Oracle Tier" |

---

## Tools for Screenshot Creation

### Free Options
- **Apple Simulator**: Built-in, high quality
- **Screenshots.pro**: Free device frames
- **Figma**: Design overlays and frames

### Paid Options
- **Rotato**: 3D device mockups
- **AppLaunchpad**: Full screenshot generator
- **Sketch**: Professional design tool
- **ScreenshotDesigner**: Specialized for App Store

---

## Localization Considerations

If localizing screenshots in the future:

1. **Text in screenshots**: Will need re-capture or editing
2. **Text overlays**: Will need translation
3. **Different zodiac systems**: Some regions use different astrology
4. **App Store Connect**: Upload per locale

Priority locales for Cosmo Trader:
1. English (US) — Primary
2. English (UK)
3. Spanish (Spain/Mexico)
4. Portuguese (Brazil)
5. German
6. French
