# Obsidian UI Styling Guide - Exact Match

This document defines the exact styling to match Obsidian's UI pixel-perfect.

## Color Palette (Dark Theme)

### Backgrounds
```swift
primaryBackground:   #1e1e1e (rgb: 30, 30, 30)
secondaryBackground: #282828 (rgb: 40, 40, 40)
tertiaryBackground:  #323232 (rgb: 50, 50, 50)
```

### Text
```swift
primaryText:   #dcdcdc (rgb: 220, 220, 220)
secondaryText: #aaaaaa (rgb: 170, 170, 170)
tertiaryText:  #808080 (rgb: 128, 128, 128)
```

### Accent
```swift
accent:       #9656e6 (rgb: 150, 86, 230) - Purple
accentHover:  #a573eb (rgb: 165, 115, 235)
destructive:  #e64c3c (rgb: 230, 76, 60)
success:      #2ecc71 (rgb: 46, 204, 113)
```

### Borders
```swift
primaryBorder:   #3c3c3c (rgb: 60, 60, 60)
secondaryBorder: #323232 (rgb: 50, 50, 50)
```

## Typography

### Font Sizes
- Tiny: 10pt (tags, metadata)
- Small: 12pt (sidebar items, secondary text)
- Body: 13pt (main content, file names)
- Medium: 14pt (headers, titles)
- Large: 16pt (editor text)
- Title: 18pt (modal titles)

### Font Weights
- Regular: .regular (400)
- Medium: .medium (500)
- Semibold: .semibold (600)

## Spacing

### Padding
- Tiny: 4pt
- Small: 8pt
- Medium: 12pt
- Large: 16pt
- XLarge: 24pt

### Gaps
- Tight: 4pt (icon + text)
- Normal: 8pt (between elements)
- Loose: 12pt (between sections)

## Border Radius

- Small: 4pt (buttons, tags)
- Medium: 6pt (cards, inputs)
- Large: 8pt (modals, panels)

## Component Specifications

### Sidebar

**Dimensions:**
- Width: 280pt
- Header height: 44pt
- Item height: 28pt
- Icon size: 16pt
- Indent per level: 20pt

**Styling:**
- Background: secondaryBackground
- Border: 1pt primaryBorder (right side)
- Item hover: tertiaryBackground
- Item active: accent with 15% opacity
- Text: primaryText (active), secondaryText (inactive)

### Tab Bar

**Dimensions:**
- Height: 36pt
- Tab padding: 12pt horizontal, 4pt vertical
- Icon size: 10pt
- Font size: 10pt medium

**Styling:**
- Background: secondaryBackground
- Active tab: tertiaryBackground with 4pt radius
- Active text: primaryText
- Inactive text: tertiaryText
- Border bottom: 1pt primaryBorder

### File List Item

**Dimensions:**
- Height: 28pt
- Padding: 8pt horizontal, 6pt vertical
- Icon size: 12pt
- Font size: 13pt

**Styling:**
- Default: transparent
- Hover: tertiaryBackground
- Selected: accent with 80% opacity
- Text: primaryText (selected), secondaryText (default)
- Border radius: 4pt

### Buttons

**Primary (Accent):**
- Background: accent
- Text: white
- Padding: 8pt horizontal, 6pt vertical
- Border radius: 4pt
- Font: 12pt medium
- Hover: accentHover

**Secondary (Gray):**
- Background: tertiaryBackground
- Text: primaryText
- Padding: 8pt horizontal, 6pt vertical
- Border radius: 4pt
- Font: 12pt medium
- Hover: lighter tertiaryBackground

**Icon Button:**
- Size: 20pt × 20pt
- Icon: 12pt
- Background: transparent
- Hover: tertiaryBackground
- Border radius: 4pt

### Input Fields

**Text Input:**
- Background: tertiaryBackground
- Border: 1pt primaryBorder
- Padding: 10pt horizontal, 8pt vertical
- Border radius: 6pt
- Font: 13pt
- Text: primaryText
- Placeholder: tertiaryText
- Focus: accent border

### Modals

**Dialog:**
- Background: primaryBackground
- Border radius: 8pt
- Shadow: 0 10pt 40pt rgba(0,0,0,0.5)
- Header height: 44pt
- Header background: secondaryBackground
- Content padding: 24pt

### Dividers

**Horizontal:**
- Height: 1pt
- Color: primaryBorder
- Margin: 0pt (full width)

**Vertical:**
- Width: 1pt
- Color: primaryBorder
- Height: 100%

## Animations

### Durations
- Fast: 0.15s (hover, focus)
- Normal: 0.25s (transitions)
- Slow: 0.35s (modals, slides)

### Easing
- Default: ease-in-out
- Bounce: spring(response: 0.4, dampingFraction: 0.7)
- Smooth: ease-out

## States

### Hover
- Background: tertiaryBackground
- Opacity: 1.0
- Transition: 0.15s

### Active/Selected
- Background: accent (15% opacity for items, 80% for buttons)
- Text: primaryText
- Border: none

### Disabled
- Opacity: 0.5
- Cursor: not-allowed
- No hover effect

### Focus
- Border: accent (2pt)
- Outline: none
- Shadow: 0 0 0 3pt accent (10% opacity)

## Icons

### Sizes
- Tiny: 12pt
- Small: 14pt
- Medium: 16pt
- Large: 20pt

### Colors
- Primary: primaryText
- Secondary: secondaryText
- Accent: accent
- Destructive: destructive

## Shadows

### Subtle
- Offset: 0 2pt
- Blur: 4pt
- Color: rgba(0,0,0,0.1)

### Medium
- Offset: 0 4pt
- Blur: 8pt
- Color: rgba(0,0,0,0.15)

### Strong
- Offset: 0 10pt
- Blur: 40pt
- Color: rgba(0,0,0,0.5)

## Implementation Checklist

- [ ] Update ColorScheme.swift with exact hex values
- [ ] Create ObsidianConstants.swift with all measurements
- [ ] Update ObsidianSidebarView with exact styling
- [ ] Update ObsidianEditorView with exact styling
- [ ] Update all button styles to match
- [ ] Update all input fields to match
- [ ] Update all modals to match
- [ ] Verify all animations match
- [ ] Test hover states
- [ ] Test active/selected states
- [ ] Test focus states
- [ ] Verify all spacing matches
- [ ] Verify all typography matches
- [ ] Verify all colors match
- [ ] Take screenshots and compare pixel-by-pixel

## Notes

- All measurements are in points (pt) for macOS
- Colors use sRGB color space
- Fonts use SF Pro (system font)
- Icons use SF Symbols
- Animations use SwiftUI's built-in animation system
- Hover effects require macOS 10.15+
