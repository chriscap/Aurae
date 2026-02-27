# Aurae iOS Design System Specification

A comprehensive design system for the Aurae headache tracking app, optimized for users with light sensitivity and chronic pain conditions.

---

## 🎨 Color System

### Light Mode Colors

```swift
// MARK: - Light Mode Colors
extension Color {
    // Primary & Accent
    static let auraeBackground = Color(hex: "#FAFBFC")
    static let auraeForeground = Color(hex: "#1F2937")
    static let auraePrimary = Color(hex: "#5B8EBF")
    static let auraePrimaryForeground = Color(hex: "#FFFFFF")
    static let auraeAccent = Color(hex: "#E8F2F9")
    static let auraeAccentForeground = Color(hex: "#7BA8D1")
    
    // Card & Surfaces
    static let auraeCard = Color(hex: "#FFFFFF")
    static let auraeCardForeground = Color(hex: "#1F2937")
    static let auraeSecondary = Color(hex: "#EFF6FC")
    static let auraeSecondaryForeground = Color(hex: "#1F2937")
    
    // Muted & Subtle
    static let auraeMuted = Color(hex: "#F3F4F6")
    static let auraeMutedForeground = Color(hex: "#6B7280")
    
    // Status Colors
    static let auraeDestructive = Color(hex: "#EF4444")
    static let auraeDestructiveForeground = Color(hex: "#FFFFFF")
    
    // Borders & Inputs
    static let auraeBorder = Color(hex: "#5B8EBF").opacity(0.2)
    static let auraeInputBackground = Color(hex: "#FFFFFF")
    static let auraeInputBorder = Color(hex: "#5B8EBF").opacity(0.2)
    
    // Intensity/Severity Colors
    static let auraeMild = Color(hex: "#10B981")      // Emerald
    static let auraeLight = Color(hex: "#14B8A6")     // Teal
    static let auraeModerate = Color(hex: "#F59E0B")  // Amber
    static let auraeSevere = Color(hex: "#F97316")    // Orange
    static let auraeExtreme = Color(hex: "#EF4444")   // Rose
    
    // Chart Colors
    static let auraeChart1 = Color(hex: "#5B8EBF")
    static let auraeChart2 = Color(hex: "#7BA8D1")
    static let auraeChart3 = Color(hex: "#4A7BA7")
    static let auraeChart4 = Color(hex: "#6A9CC6")
    static let auraeChart5 = Color(hex: "#8BB5D8")
}
```

### Dark Mode Colors

```swift
// MARK: - Dark Mode Colors
extension Color {
    // Primary & Accent
    static let auraeBackgroundDark = Color(hex: "#121B28")
    static let auraeForegroundDark = Color(hex: "#E1E9F2")
    static let auraePrimaryDark = Color(hex: "#6FA8DC")
    static let auraePrimaryForegroundDark = Color(hex: "#0F1419")
    static let auraeAccentDark = Color(hex: "#253545")
    static let auraeAccentForegroundDark = Color(hex: "#A4BED6")
    
    // Card & Surfaces
    static let auraeCardDark = Color(hex: "#1A2332")
    static let auraeCardForegroundDark = Color(hex: "#E1E9F2")
    static let auraeSecondaryDark = Color(hex: "#1E2A38")
    static let auraeSecondaryForegroundDark = Color(hex: "#E1E9F2")
    
    // Muted & Subtle
    static let auraeMutedDark = Color(hex: "#1E2A38")
    static let auraeMutedForegroundDark = Color(hex: "#8A9BAD")
    
    // Status Colors
    static let auraeDestructiveDark = Color(hex: "#D87A7A")
    static let auraeDestructiveForegroundDark = Color(hex: "#0F1419")
    
    // Borders & Inputs
    static let auraeBorderDark = Color(hex: "#6FA8DC").opacity(0.15)
    static let auraeInputBackgroundDark = Color(hex: "#1E2A38")
    static let auraeInputBorderDark = Color(hex: "#6FA8DC").opacity(0.15)
    
    // Chart Colors (Dark Mode)
    static let auraeChart1Dark = Color(hex: "#6FA8DC")
    static let auraeChart2Dark = Color(hex: "#5B8EBF")
    static let auraeChart3Dark = Color(hex: "#8BB5D8")
    static let auraeChart4Dark = Color(hex: "#7BA8D1")
    static let auraeChart5Dark = Color(hex: "#9AC4E4")
}
```

### Helper Extension for Hex Colors

```swift
// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## 📐 Typography System

### Font Weights

```swift
// MARK: - Font Weights
enum AuraeFontWeight {
    static let regular: Font.Weight = .regular    // 400
    static let medium: Font.Weight = .medium      // 500
    static let semibold: Font.Weight = .semibold  // 600
    static let bold: Font.Weight = .bold          // 700
}
```

### Typography Scale

```swift
// MARK: - Typography Scale
extension Font {
    // Display / Hero Text
    static let auraeHero = Font.system(size: 48, weight: .bold)           // 48pt, 700
    
    // Large Title
    static let auraeLargeTitle = Font.system(size: 34, weight: .bold)     // 34pt, 700
    
    // Title 1
    static let auraeTitle1 = Font.system(size: 28, weight: .bold)         // 28pt, 700
    
    // Title 2
    static let auraeTitle2 = Font.system(size: 24, weight: .bold)         // 24pt, 700
    
    // Title 3
    static let auraeTitle3 = Font.system(size: 20, weight: .semibold)     // 20pt, 600
    
    // Headline
    static let auraeHeadline = Font.system(size: 18, weight: .semibold)   // 18pt, 600
    
    // Body
    static let auraeBody = Font.system(size: 16, weight: .regular)        // 16pt, 400
    static let auraeBodyBold = Font.system(size: 16, weight: .semibold)   // 16pt, 600
    
    // Callout
    static let auraeCallout = Font.system(size: 14, weight: .regular)     // 14pt, 400
    static let auraeCalloutBold = Font.system(size: 14, weight: .semibold) // 14pt, 600
    
    // Footnote
    static let auraeFootnote = Font.system(size: 13, weight: .regular)    // 13pt, 400
    
    // Caption
    static let auraeCaption = Font.system(size: 12, weight: .regular)     // 12pt, 400
    static let auraeCaptionBold = Font.system(size: 12, weight: .medium)  // 12pt, 500
    
    // Caption 2 (smallest)
    static let auraeCaption2 = Font.system(size: 10, weight: .regular)    // 10pt, 400
}
```

### Line Height Guidelines

```swift
// MARK: - Line Heights
enum AuraeLineHeight {
    static let tight: CGFloat = 1.2      // For large headings
    static let normal: CGFloat = 1.5     // Default for body text
    static let relaxed: CGFloat = 1.6    // For better readability
    static let loose: CGFloat = 1.8      // For very spaced content
}
```

---

## 📏 Spacing System

```swift
// MARK: - Spacing Scale
enum AuraeSpacing {
    static let xxxs: CGFloat = 2    // 2pt
    static let xxs: CGFloat = 4     // 4pt
    static let xs: CGFloat = 8      // 8pt
    static let sm: CGFloat = 12     // 12pt
    static let md: CGFloat = 16     // 16pt
    static let lg: CGFloat = 20     // 20pt
    static let xl: CGFloat = 24     // 24pt
    static let xxl: CGFloat = 32    // 32pt
    static let xxxl: CGFloat = 48   // 48pt
    static let huge: CGFloat = 64   // 64pt
}
```

### Common Padding Values

```swift
// MARK: - Padding Presets
enum AuraePadding {
    // Screen edges
    static let screenHorizontal: CGFloat = 24  // Standard horizontal padding
    static let screenTop: CGFloat = 56         // Top padding (below status bar)
    
    // Cards
    static let cardPadding: CGFloat = 20       // Inside cards
    static let cardSmall: CGFloat = 16         // Compact cards
    static let cardLarge: CGFloat = 24         // Spacious cards
    
    // Components
    static let buttonVertical: CGFloat = 16    // Button padding
    static let buttonHorizontal: CGFloat = 24  // Button padding
}
```

---

## 🔲 Border Radius

```swift
// MARK: - Border Radius
enum AuraeRadius {
    static let xs: CGFloat = 8      // Small elements
    static let sm: CGFloat = 12     // Buttons, inputs
    static let md: CGFloat = 16     // Cards
    static let lg: CGFloat = 20     // Large cards
    static let xl: CGFloat = 24     // Hero cards
    static let xxl: CGFloat = 32    // Extra large cards
    static let full: CGFloat = 9999 // Circular/pill shape
}
```

---

## 🌑 Shadows & Elevation

```swift
// MARK: - Shadow Styles
struct AuraeShadow {
    // Subtle shadow for cards
    static let card: ShadowStyle = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
    )
    
    // Medium shadow for elevated elements
    static let elevated: ShadowStyle = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 16,
        x: 0,
        y: 4
    )
    
    // Strong shadow for prominent elements
    static let prominent: ShadowStyle = ShadowStyle(
        color: Color.auraePrimary.opacity(0.3),
        radius: 24,
        x: 0,
        y: 8
    )
    
    // Glow effect for primary actions
    static let primaryGlow: ShadowStyle = ShadowStyle(
        color: Color.auraePrimary.opacity(0.4),
        radius: 20,
        x: 0,
        y: 8
    )
}

// Helper struct
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// SwiftUI Extension
extension View {
    func auraeShadow(_ shadowStyle: ShadowStyle) -> some View {
        self.shadow(
            color: shadowStyle.color,
            radius: shadowStyle.radius,
            x: shadowStyle.x,
            y: shadowStyle.y
        )
    }
}
```

---

## 🎭 Gradient System

```swift
// MARK: - Gradient Styles
struct AuraeGradient {
    // Primary gradient (main brand)
    static let primary = LinearGradient(
        colors: [Color.auraePrimary, Color.auraeAccentForeground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Primary gradient with accessibility overlay (REQUIRED for text on gradients)
    static func primaryAccessible<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.auraePrimary, Color.auraeAccentForeground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color.black.opacity(0.2)  // CRITICAL: 20% overlay for contrast
            
            content()
                .zIndex(10)
        }
    }
    
    // Success gradient
    static let success = LinearGradient(
        colors: [Color.auraeMild, Color.auraeLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Success gradient with accessibility overlay
    static func successAccessible<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.auraeMild, Color.auraeLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color.black.opacity(0.2)
            
            content()
                .zIndex(10)
        }
    }
    
    // Accent gradient (subtle)
    static let accent = LinearGradient(
        colors: [Color.auraeAccent, Color(hex: "#E3F2FD")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

---

## 🧩 Component Specifications

### Bottom Navigation Bar

```swift
// MARK: - Bottom Navigation Specs
enum BottomNavSpecs {
    static let height: CGFloat = 83
    static let iconSize: CGFloat = 24
    static let labelFont: Font = .auraeCaption
    static let selectedColor: Color = .auraePrimary
    static let unselectedColor: Color = .auraeMutedForeground
    static let backgroundColor: Color = .auraeCard
    static let blurEffect: Bool = true
}

struct TabItem {
    let title: String
    let icon: String  // SF Symbol name
    let selectedIcon: String?  // Optional filled variant
}
```

### Cards

```swift
// MARK: - Card Component
struct AuraeCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AuraeRadius.lg)
            .fill(Color.auraeCard)
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.lg)
                    .stroke(Color.auraeBorder, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// Usage Specs:
// - Corner Radius: 16-24pt (md-xl)
// - Padding: 16-24pt
// - Border: 1pt with auraeBorder color
// - Shadow: subtle (see shadows)
```

### Buttons

```swift
// MARK: - Button Styles
enum AuraeButtonStyle {
    case primary      // Gradient background, white text
    case secondary    // Muted background, foreground text
    case ghost        // No background, colored text
    case destructive  // Red/destructive color
}

struct AuraeButtonSpecs {
    static let height: CGFloat = 56
    static let cornerRadius: CGFloat = AuraeRadius.md
    static let font: Font = .auraeBody.weight(.semibold)
    static let horizontalPadding: CGFloat = 24
    static let verticalPadding: CGFloat = 16
}

// Primary Button with Gradient Example:
struct AuraePrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.auraePrimary, Color.auraeAccentForeground],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                // CRITICAL: Accessibility overlay for contrast
                Color.black.opacity(0.2)
                
                // Content
                Text(title)
                    .font(.auraeBody.weight(.semibold))
                    .foregroundColor(.white)
                    .zIndex(10)
            }
        }
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md))
        .shadow(color: Color.auraePrimary.opacity(0.3), radius: 20, x: 0, y: 8)
    }
}
```

### Selection Components

```swift
// MARK: - Selection Chip (Multi-select pills)
struct SelectionChipSpecs {
    static let height: CGFloat = 44
    static let horizontalPadding: CGFloat = 20
    static let cornerRadius: CGFloat = AuraeRadius.full
    static let borderWidth: CGFloat = 2
    static let font: Font = .auraeCallout.weight(.medium)
    
    // Selected state
    static let selectedBackground: Color = .auraeAccent
    static let selectedBorder: Color = .auraePrimary
    static let selectedText: Color = .auraeAccentForeground
    
    // Unselected state
    static let unselectedBackground: Color = .auraeCard
    static let unselectedBorder: Color = .auraeBorder
    static let unselectedText: Color = .auraeForeground
}

// MARK: - Selection Card (Single-select cards)
struct SelectionCardSpecs {
    static let cornerRadius: CGFloat = AuraeRadius.md
    static let padding: CGFloat = 16
    static let borderWidth: CGFloat = 2
    static let font: Font = .auraeBody.weight(.medium)
    
    // Selected state
    static let selectedBackground: Color = .auraeAccent
    static let selectedBorder: Color = .auraePrimary
    
    // Unselected state
    static let unselectedBackground: Color = .auraeCard
    static let unselectedBorder: Color = .auraeBorder
}
```

### Intensity Selector (Pain Scale)

```swift
// MARK: - Intensity Level
struct IntensityLevel {
    let value: Int
    let label: String
    let color: Color
}

let intensityLevels: [IntensityLevel] = [
    IntensityLevel(value: 1, label: "Mild", color: .auraeMild),
    IntensityLevel(value: 2, label: "Light", color: .auraeLight),
    IntensityLevel(value: 3, label: "Moderate", color: .auraeModerate),
    IntensityLevel(value: 4, label: "Severe", color: .auraeSevere),
    IntensityLevel(value: 5, label: "Extreme", color: .auraeExtreme)
]

struct IntensityCardSpecs {
    static let height: CGFloat = 64
    static let cornerRadius: CGFloat = AuraeRadius.md
    static let padding: CGFloat = 16
    static let indicatorSize: CGFloat = 16  // Color dot
    static let spacing: CGFloat = 8         // Between cards
}
```

### Status Cards (with gradient backgrounds)

```swift
// MARK: - Status Card (e.g., Streak Card)
struct StatusCardSpecs {
    static let cornerRadius: CGFloat = AuraeRadius.md
    static let padding: CGFloat = 20
    static let iconContainerSize: CGFloat = 28
    static let iconSize: CGFloat = 16
    static let titleFont: Font = .auraeCaption.weight(.medium)
    static let valueFont: Font = .system(size: 36, weight: .bold)
    static let subtitleFont: Font = .auraeCaption
    
    // CRITICAL: Background uses gradient with 20% black overlay for accessibility
    static let overlayOpacity: CGFloat = 0.2
}

// Example Implementation:
struct StatusCard: View {
    var body: some View {
        ZStack {
            // Gradient
            LinearGradient(
                colors: [Color.auraePrimary, Color.auraeAccentForeground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // REQUIRED: Accessibility overlay
            Color.black.opacity(0.2)
            
            // Content
            VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
                // Your content here
            }
            .foregroundColor(.white)
            .zIndex(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md))
    }
}
```

### Context Capture Card (Weather/Location)

```swift
// MARK: - Context Capture Card
struct ContextCardSpecs {
    static let cornerRadius: CGFloat = AuraeRadius.xl  // 24pt
    static let padding: CGFloat = 24
    static let iconContainerSize: CGFloat = 32
    static let iconSize: CGFloat = 16
    static let titleFont: Font = .auraeBody.weight(.semibold)
    static let labelFont: Font = .auraeCallout.weight(.medium)
    static let sublabelFont: Font = .auraeCaption
    static let itemSpacing: CGFloat = 12
    
    // Uses solid card background with border for accessibility
    static let background: Color = .auraeCard
    static let border: Color = .auraeBorder
    static let borderWidth: CGFloat = 1
}
```

### Stats Grid

```swift
// MARK: - Stat Card
struct StatCardSpecs {
    static let cornerRadius: CGFloat = AuraeRadius.sm
    static let padding: CGFloat = 16
    static let iconContainerSize: CGFloat = 36
    static let iconSize: CGFloat = 16
    static let valueFont: Font = .system(size: 24, weight: .bold)
    static let labelFont: Font = .auraeCaption
    static let spacing: CGFloat = 12  // Grid gap
}
```

### Insight Cards

```swift
// MARK: - Insight Card
struct InsightCardSpecs {
    static let cornerRadius: CGFloat = AuraeRadius.sm
    static let padding: CGFloat = 14
    static let iconContainerSize: CGFloat = 36
    static let iconSize: CGFloat = 16
    static let titleFont: Font = .auraeCallout.weight(.medium)
    static let descriptionFont: Font = .auraeCaption
    static let spacing: CGFloat = 10  // Between cards
}
```

---

## 🎬 Animation Guidelines

### Timing Functions

```swift
// MARK: - Animation Timings
enum AuraeAnimation {
    // Durations
    static let fast: TimeInterval = 0.2
    static let normal: TimeInterval = 0.3
    static let slow: TimeInterval = 0.5
    static let verySlow: TimeInterval = 0.8
    
    // Spring animations
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // Easing
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
}
```

### Common Animations

```swift
// MARK: - Animation Patterns

// Fade in from top
.onAppear {
    withAnimation(.easeOut(duration: 0.5)) {
        // Opacity: 0 -> 1
        // Offset Y: -20 -> 0
    }
}

// Scale in
.onAppear {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        // Scale: 0.95 -> 1
        // Opacity: 0 -> 1
    }
}

// Slide in from left
.onAppear {
    withAnimation(.easeOut(duration: 0.3)) {
        // Offset X: -20 -> 0
        // Opacity: 0 -> 1
    }
}

// Button press
.scaleEffect(pressed ? 0.95 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)

// Progress bar fill
.animation(.easeOut(duration: 0.8), value: percentage)
```

### Staggered Animations

```swift
// For lists - stagger by 0.1s per item
ForEach(items.indices, id: \.self) { index in
    ItemView(item: items[index])
        .transition(.opacity.combined(with: .offset(y: 20)))
        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.1), value: isShowing)
}
```

---

## 📱 Screen Layout Patterns

### Safe Areas & Margins

```swift
// MARK: - Layout Guidelines
enum AuraeLayout {
    // Screen margins
    static let horizontalMargin: CGFloat = 24
    static let topMargin: CGFloat = 56      // Below status bar + header
    static let bottomMargin: CGFloat = 100  // Above tab bar
    
    // Section spacing
    static let sectionSpacing: CGFloat = 24
    static let componentSpacing: CGFloat = 12
    
    // Grid gaps
    static let gridGap: CGFloat = 12
}
```

### Header Pattern

```swift
// All main screens follow this pattern:
// - Top padding: 56-64pt
// - Large title: 48pt bold (Hero) or 34pt bold (Large Title)
// - Subtitle: 16pt regular, muted foreground
// - Margin bottom: 32pt
```

### Content Sections

```swift
// Pattern for content sections:
// 1. Section header with title and optional "View All" link
// 2. Content cards with consistent spacing
// 3. Spacing between sections: 24pt
```

---

## ♿️ Accessibility Features

### Text Contrast Requirements

All text must meet WCAG AA standards:
- **Normal text (< 18pt):** 4.5:1 contrast ratio minimum
- **Large text (≥ 18pt):** 3.0:1 contrast ratio minimum

**CRITICAL: Gradient Backgrounds with Text**

All gradient backgrounds that contain text MUST include a 20% black overlay to meet accessibility standards:

```swift
// ✅ CORRECT - With accessibility overlay
ZStack {
    LinearGradient(
        colors: [Color.auraePrimary, Color.auraeAccentForeground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    Color.black.opacity(0.2)  // REQUIRED
    
    Text("Your content")
        .foregroundColor(.white)
        .zIndex(10)
}

// ❌ INCORRECT - Missing overlay
ZStack {
    LinearGradient(
        colors: [Color.auraePrimary, Color.auraeAccentForeground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    Text("Your content")
        .foregroundColor(.white)
}
```

### Accessible Text Colors

```swift
// MARK: - Accessible Color Pairs
// These combinations meet WCAG AA standards:

// Light Mode:
// - auraeForeground (#1F2937) on auraeBackground (#FAFBFC) ✅
// - auraeForeground (#1F2937) on auraeCard (#FFFFFF) ✅
// - auraeMutedForeground (#6B7280) on auraeCard (#FFFFFF) ✅
// - White text on gradient with 20% black overlay ✅

// Dark Mode:
// - auraeForegroundDark (#E1E9F2) on auraeBackgroundDark (#121B28) ✅
// - auraeForegroundDark (#E1E9F2) on auraeCardDark (#1A2332) ✅
// - auraeMutedForegroundDark (#8A9BAD) on auraeCardDark (#1A2332) ✅

// Always avoid:
// - Light text on light backgrounds
// - accent-foreground text on gradient backgrounds without overlay
```

### Dynamic Type Support

```swift
// Support for user font size preferences
Text("Headache-free streak")
    .font(.auraeCaption)
    .dynamicTypeSize(.medium...(.xxxLarge))  // Limit max size for layout stability
```

### Color Considerations

- **Light Sensitivity:** All colors are calibrated to avoid harsh brightness
- **Dark Mode:** Essential for migraine sufferers - never pure white backgrounds
- **Blue Light:** Primary colors use softer, muted blues (#5B8EBF, #6FA8DC)
- **Avoid:** Pure white (#FFFFFF), pure black (#000000), bright reds, neon colors

---

## 🎯 Usage Examples

### Creating a Screen with Header

```swift
struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraeSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AuraeSpacing.xs) {
                    Text("Good morning")
                        .font(.auraeLargeTitle)
                        .foregroundColor(.auraeForeground)
                    
                    Text("Wednesday, Feb 25")
                        .font(.auraeCaption)
                        .foregroundColor(.auraeMutedForeground)
                }
                .padding(.top, AuraePadding.screenTop)
                
                // Status Card with accessible gradient
                ZStack {
                    LinearGradient(
                        colors: [Color.auraePrimary, Color.auraeAccentForeground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Color.black.opacity(0.2)  // Accessibility overlay
                    
                    VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
                        HStack(spacing: AuraeSpacing.xs) {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text("Headache-free streak")
                                .font(.auraeCaption.weight(.medium))
                        }
                        .opacity(0.9)
                        
                        Text("7")
                            .font(.system(size: 36, weight: .bold))
                        
                        Text("days and counting")
                            .font(.auraeCaption)
                            .opacity(0.75)
                    }
                    .foregroundColor(.white)
                    .padding(AuraePadding.cardPadding)
                    .zIndex(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md))
                .shadow(color: Color.auraePrimary.opacity(0.2), radius: 16, x: 0, y: 4)
            }
            .padding(.horizontal, AuraeLayout.horizontalMargin)
        }
        .background(Color.auraeBackground)
    }
}
```

### Creating an Accessible Button

```swift
// Primary action button with gradient and accessibility overlay
Button(action: logHeadache) {
    ZStack {
        LinearGradient(
            colors: [Color.auraePrimary, Color.auraeAccentForeground],
            startPoint: .leading,
            endPoint: .trailing
        )
        Color.black.opacity(0.2)  // REQUIRED for accessibility
        
        HStack(spacing: AuraeSpacing.sm) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
            Text("Log Headache")
                .font(.auraeBody.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.vertical, AuraePadding.buttonVertical)
        .zIndex(10)
    }
}
.frame(height: 56)
.clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md))
.shadow(color: Color.auraePrimary.opacity(0.3), radius: 20, x: 0, y: 8)
```

### Creating an Accessible Context Card

```swift
// Weather/Location card with proper contrast
VStack(alignment: .leading, spacing: AuraeSpacing.md) {
    HStack(spacing: AuraeSpacing.xs) {
        Image(systemName: "waveform.path.ecg")
            .font(.system(size: 20))
            .foregroundColor(.auraePrimary)
        Text("Capturing context")
            .font(.auraeBody.weight(.semibold))
            .foregroundColor(.auraeForeground)
    }
    
    VStack(spacing: AuraeSpacing.sm) {
        HStack(spacing: AuraeSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.auraeAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.auraePrimary)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Location: San Francisco")
                    .font(.auraeCallout.weight(.medium))
                    .foregroundColor(.auraeForeground)
                Text("Automatically detected")
                    .font(.auraeCaption)
                    .foregroundColor(.auraeMutedForeground)
            }
        }
    }
}
.padding(24)
.background(Color.auraeCard)
.clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xl))
.overlay(
    RoundedRectangle(cornerRadius: AuraeRadius.xl)
        .stroke(Color.auraeBorder, lineWidth: 1)
)
.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
```

---

## 📦 Component Library Checklist

When building components, ensure:

- ✅ Supports both light and dark mode
- ✅ Uses design system colors (no hardcoded hex values)
- ✅ Follows spacing scale
- ✅ Uses correct typography
- ✅ Includes appropriate shadows
- ✅ Has smooth animations (spring or ease-out)
- ✅ **Meets accessibility contrast requirements (CRITICAL)**
- ✅ **All gradient backgrounds with text have 20% black overlay**
- ✅ Supports Dynamic Type
- ✅ Has proper touch targets (minimum 44x44pt)
- ✅ Includes haptic feedback for interactions

---

## 🎨 Design Principles

1. **Calming First:** Every design decision prioritizes comfort for users in pain
2. **Bold Typography:** Clear hierarchy with generous font sizes
3. **Generous Whitespace:** Never crowded, always breathing room
4. **Soft Colors:** Muted blues, never harsh or bright
5. **Accessible Gradients:** 20% black overlay on ALL gradient backgrounds with text
6. **Smooth Interactions:** Gentle spring animations, no jarring movements
7. **Consistent Patterns:** Predictable layouts reduce cognitive load
8. **Dark Mode Default:** Essential for light-sensitive users

---

## 🚨 Common Mistakes to Avoid

### ❌ Missing Accessibility Overlay
```swift
// WRONG - Gradient with text, no overlay
ZStack {
    LinearGradient(colors: [.auraePrimary, .auraeAccentForeground])
    Text("Streak: 7 days")
        .foregroundColor(.white)
}
```

### ✅ Correct Implementation
```swift
// RIGHT - Gradient with required overlay
ZStack {
    LinearGradient(colors: [.auraePrimary, .auraeAccentForeground])
    Color.black.opacity(0.2)  // REQUIRED
    Text("Streak: 7 days")
        .foregroundColor(.white)
        .zIndex(10)
}
```

### ❌ Poor Contrast
```swift
// WRONG - Light text on light background
Text("Info")
    .foregroundColor(.auraeMutedForeground)
    .padding()
    .background(Color.auraeAccent)
```

### ✅ Correct Implementation
```swift
// RIGHT - Dark text on light background
Text("Info")
    .foregroundColor(.auraeForeground)
    .padding()
    .background(Color.auraeCard)
```

---

## 📝 Notes

- This design system is specifically optimized for iOS 15+ using SwiftUI
- All measurements are in points (pt) which automatically scale for different device sizes
- Color names are prefixed with "aurae" to avoid conflicts with system colors
- **The 20% black overlay on gradients is MANDATORY for accessibility - never skip it**
- Test all designs in both light and dark mode
- Always verify text contrast ratios meet WCAG AA standards
- Consider using SF Symbols for icons to maintain consistency with iOS design language
- Use haptic feedback (UIImpactFeedbackGenerator) for button interactions

---

**Version:** 2.0  
**Last Updated:** February 2026  
**Changes:** Added accessibility overlay requirements, fixed context card contrast, updated all gradient examples  
**Figma Make Source:** Aurae iOS App Design
