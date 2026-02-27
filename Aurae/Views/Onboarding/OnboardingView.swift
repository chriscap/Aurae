//
//  OnboardingView.swift
//  Aurae
//
//  Full-screen onboarding presented on first launch as a .fullScreenCover.
//  Dismissed when the user taps "Let's go" on the final screen, which sets
//  @AppStorage("hasCompletedOnboarding") = true in AuraeApp.
//
//  6 screens delivered via a TabView with .page style:
//    1. Welcome        — headline + logo + "Get Started"
//    2. How it works   — 3 auto-capture feature rows + "Next"
//    3. Retrospective  — 3 manual-entry feature rows + "Next"
//    4. Insights       — premium preview card (locked) + "Next"
//    5. Safety         — red-flag symptoms + aura clarification + "Next"
//    6. Permissions    — 3 permission explanations + "Let's go"
//
//  Navigation rules:
//  - "Get Started" on screen 1 advances to screen 2.
//  - "Next" on screens 2–4 advances one step.
//  - "Skip" (top-right toolbar) on screens 2–4 jumps to screen 5.
//  - "Let's go" on screen 5 calls the onComplete closure.
//  - Swipe-to-advance is enabled by default via .page TabView style.
//
//  Swift 6 notes:
//  - OnboardingView is a pure value type (struct). No actor isolation needed.
//  - The onComplete closure is @escaping because it is stored and called later.
//  - TabView page index is driven by @State — always written on the main thread.
//

import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    /// Called when the user completes or skips past all onboarding screens.
    /// AuraeApp sets hasCompletedOnboarding = true and dismisses the cover.
    var onComplete: () -> Void

    @State private var currentPage: Int = 0

    // The total number of pages — used for the dot indicator and bounds checks.
    private let pageCount: Int = 6

    // Page indices as constants to avoid magic literals throughout.
    private enum Page {
        static let welcome:       Int = 0
        static let howItWorks:    Int = 1
        static let retrospective: Int = 2
        static let insights:      Int = 3
        static let safety:        Int = 4
        static let permissions:   Int = 5
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.auraeAdaptiveBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button row — visible only on screens 2–4
                skipRow
                    .frame(height: 44)

                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage(onNext: advance)
                        .tag(Page.welcome)

                    HowItWorksPage(onNext: advance)
                        .tag(Page.howItWorks)

                    RetrospectivePage(onNext: advance)
                        .tag(Page.retrospective)

                    InsightsPage(onNext: advance)
                        .tag(Page.insights)

                    SafetyPage(onNext: advance)
                        .tag(Page.safety)

                    PermissionsPage(onComplete: onComplete)
                        .tag(Page.permissions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentPage)

                // Custom page dots
                pageDots
                    .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Skip row

    @ViewBuilder
    private var skipRow: some View {
        HStack {
            Spacer()
            if currentPage >= Page.howItWorks && currentPage <= Page.safety {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        currentPage = Page.permissions
                    }
                } label: {
                    Text("Skip")
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeMidGray)
                }
                .padding(.trailing, Layout.screenPadding)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }

    // MARK: - Page dot indicator

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.auraeTeal : Color.auraeAdaptiveSecondary)
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.top, 12)
        // Page dots are decorative position indicators. VoiceOver users navigate
        // through page content sequentially via swipe; the dots carry no unique
        // information beyond what is visible on each page. (A18-09)
        .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private func advance() {
        guard currentPage < pageCount - 1 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Decorative logo mark — app name "Aurae" in the headline below
            // conveys identity to VoiceOver users. (A18-09)
            ZStack {
                Circle()
                    .fill(Color.auraeTeal)
                    .frame(width: 96, height: 96)
                Text("A")
                    .font(.fraunces(52, weight: .bold))
                    .foregroundStyle(Color.auraeDeepSlate)
            }
            .padding(.bottom, 36)
            .accessibilityHidden(true)

            // Headline
            Text("Understand your headaches.")
                .font(.fraunces(34, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 20)

            // Subtitle
            Text("Aurae automatically captures weather, sleep, and health data the moment a headache starts — so you can find your triggers.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Layout.screenPadding + 8)

            Spacer()
            Spacer()

            AuraeButton("Get Started", action: onNext)
                .accessibilityHint("Continues to the next onboarding step")
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Layout.itemSpacing)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Screen 2: How it works

private struct HowItWorksPage: View {
    let onNext: () -> Void

    private let features: [(icon: String, color: Color, text: String)] = [
        (
            "bolt.fill",
            .auraeTeal,
            "Tap once to log. Aurae captures everything automatically."
        ),
        (
            "waveform.path.ecg",
            Color.auraeIndigo,
            "Heart rate, sleep, and activity from Apple Health, captured at onset."
        ),
        (
            "cloud.sun.fill",
            Color.auraeAmber,
            "Local weather conditions recorded the moment you log."
        )
    ]

    var body: some View {
        OnboardingPageShell(
            headline: "Log in seconds.",
            onNext: onNext
        ) {
            ForEach(features, id: \.text) { feature in
                FeatureRow(
                    icon: feature.icon,
                    iconColor: feature.color,
                    description: feature.text
                )
            }
        }
    }
}

// MARK: - Screen 3: Retrospective

private struct RetrospectivePage: View {
    let onNext: () -> Void

    private let features: [(icon: String, color: Color, text: String)] = [
        (
            "fork.knife",
            Color.auraeDarkSage,
            "What you ate and drank."
        ),
        (
            "moon.stars.fill",
            Color.auraeIndigo,
            "Sleep and stress levels."
        ),
        (
            "pill.fill",
            Color.auraeDestructive,   // muted red — no token yet, matches severityAccent(for: 5)
            "Medication and effectiveness."
        )
    ]

    var body: some View {
        OnboardingPageShell(
            headline: "Fill in the rest.",
            subtitle: "Add food, stress, sleep quality, and medication after the headache passes. The more you log, the smarter Aurae gets.",
            onNext: onNext
        ) {
            ForEach(features, id: \.text) { feature in
                FeatureRow(
                    icon: feature.icon,
                    iconColor: feature.color,
                    description: feature.text
                )
            }
        }
    }
}

// MARK: - Screen 4: Insights (premium preview)

private struct InsightsPage: View {
    let onNext: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Headline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Discover your triggers.")
                        .font(.fraunces(28, weight: .semibold))
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Text("Aurae Pro analyses your patterns and surfaces your personal triggers — weather pressure drops, poor sleep, skipped meals, and more.")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeMidGray)
                        .lineSpacing(4)
                }
                .padding(.top, 8)

                // Mock insights card with lock overlay
                MockInsightsCard()
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            AuraeButton("Next", action: onNext)
                .accessibilityHint("Continues to the permissions setup step")
                .padding(.horizontal, Layout.screenPadding)
                .padding(.vertical, Layout.itemSpacing)
                .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - Mock insights card (locked premium preview)

private struct MockInsightsCard: View {

    var body: some View {
        ZStack {
            // Blurred background card — gradient acts as a stand-in for a
            // future Swift Charts preview. Blur applied via ZStack layering
            // with an overlay rather than .blur() to keep the card shape crisp.
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.auraeAdaptiveSoftTeal, Color.auraeAdaptiveSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)
                .overlay(mockChartLines)
                .overlay(
                    // Frosted glass effect — adaptive overlay adapts to Dark Mode.
                    RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                        .fill(Color.auraeAdaptiveCard.opacity(0.55))
                )

            // Lock badge — decorative; heading "Unlock with Aurae Pro" below carries meaning.
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.auraeTeal)
                        .frame(width: 52, height: 52)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.auraeDeepSlate)
                }
                .accessibilityHidden(true)

                Text("Unlock with Aurae Pro")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }
        }
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
        // The entire mock card is a decorative preview illustration.
        // The surrounding page text explains the premium feature. (A18-09)
        .accessibilityHidden(true)
    }

    // Decorative horizontal bars mimicking a chart inside the blurred card
    private var mockChartLines: some View {
        VStack(spacing: 14) {
            ForEach(0..<5, id: \.self) { i in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraeTeal.opacity(0.35))
                        .frame(width: CGFloat([120, 80, 160, 100, 140][i]), height: 10)
                    Spacer()
                }
            }
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: - Screen 5: Safety

/// "Before you start logging" — red-flag symptom awareness and aura clarification.
/// Clinical requirement: shown once to every new user during onboarding.
private struct SafetyPage: View {
    let onNext: () -> Void

    private struct RedFlagItem {
        let icon: String
        let color: Color
        let text: String
    }

    private let items: [RedFlagItem] = [
        RedFlagItem(
            icon: "bolt.fill",
            color: Color.auraeDestructive,
            text: "A sudden, severe headache unlike any you've had before."
        ),
        RedFlagItem(
            icon: "thermometer.medium",
            color: Color.auraeAmber,
            text: "Headache with fever, stiff neck, confusion, or vision changes."
        ),
        RedFlagItem(
            icon: "figure.fall",
            color: Color.auraeIndigo,
            text: "A headache following a head injury."
        ),
        RedFlagItem(
            icon: "waveform.path.ecg",
            color: Color.auraeIndigo,
            text: "New weakness, numbness, or difficulty speaking."
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before you start logging.")
                        .font(.fraunces(28, weight: .semibold))
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Text("Aurae is designed for recurring headaches you already know about.")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeMidGray)
                        .lineSpacing(4)
                }
                .padding(.top, 8)

                // Red flag symptom rows
                VStack(spacing: Layout.itemSpacing) {
                    ForEach(items, id: \.text) { item in
                        FeatureRow(
                            icon: item.icon,
                            iconColor: item.color,
                            description: item.text
                        )
                    }
                }

                // Seek-care callout
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.auraeDestructive)
                        .accessibilityHidden(true)
                    Text("If you experience any of these, please seek medical care right away. These symptoms are not what this app is designed to track.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.auraeAdaptiveBlush)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)

                // Aura name clarification
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.auraePrimary)
                        .accessibilityHidden(true)
                    Text("Aurae is designed for anyone who experiences recurring headaches, whether or not you experience aura or have a migraine diagnosis.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.auraeAdaptiveSoftTeal)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            AuraeButton("Next", action: onNext)
                .accessibilityHint("Continues to permissions setup")
                .padding(.horizontal, Layout.screenPadding)
                .padding(.vertical, Layout.itemSpacing)
                .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - Screen 6: Permissions

private struct PermissionsPage: View {
    let onComplete: () -> Void

    private struct PermissionItem {
        let icon: String
        let iconColor: Color
        let title: String
        let detail: String
    }

    private let permissions: [PermissionItem] = [
        PermissionItem(
            icon:       "heart.fill",
            iconColor:  Color.auraeDestructive,   // matches severityAccent(for: 5)
            title:      "Apple Health",
            detail:     "Read sleep, heart rate, and activity at headache onset. Never written to."
        ),
        PermissionItem(
            icon:       "location.fill",
            iconColor:  .auraeTeal,
            title:      "Location",
            detail:     "Used once per log to fetch local weather. Never stored."
        ),
        PermissionItem(
            icon:       "bell.fill",
            iconColor:  Color.auraeAmber,
            title:      "Notifications",
            detail:     "Optional follow-up reminder to complete your log."
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Headline
                VStack(alignment: .leading, spacing: 12) {
                    Text("A few quick permissions.")
                        .font(.fraunces(28, weight: .semibold))
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                }
                .padding(.top, 8)

                // Permission items
                VStack(spacing: Layout.itemSpacing) {
                    ForEach(permissions, id: \.title) { item in
                        PermissionRow(
                            icon:      item.icon,
                            iconColor: item.iconColor,
                            title:     item.title,
                            detail:    item.detail
                        )
                    }
                }

                // Opt-out reassurance
                HStack(spacing: 8) {
                    // Decorative shield — text below conveys the message. (A18-09)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.auraeTeal)
                        .accessibilityHidden(true)
                    Text("All permissions are optional. Aurae works without them.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.auraeAdaptiveSoftTeal)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            AuraeButton("Let's go", action: onComplete)
                .accessibilityHint("Completes onboarding and opens the app")
                .padding(.horizontal, Layout.screenPadding)
                .padding(.vertical, Layout.itemSpacing)
                .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - Shared shell for pages 2 & 3

/// Provides the standard layout for feature-list pages:
/// headline, optional subtitle, feature rows injected via content, and a
/// "Next" button pinned to the bottom.
private struct OnboardingPageShell<Content: View>: View {
    let headline: String
    var subtitle: String? = nil
    let onNext: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Headline + optional subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text(headline)
                        .font(.fraunces(28, weight: .semibold))
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    if let sub = subtitle {
                        Text(sub)
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeMidGray)
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 8)

                // Feature rows
                VStack(spacing: Layout.itemSpacing) {
                    content()
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            AuraeButton("Next", action: onNext)
                .accessibilityHint("Continues to the next onboarding step")
                .padding(.horizontal, Layout.screenPadding)
                .padding(.vertical, Layout.itemSpacing)
                .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - FeatureRow

/// A 44×44 teal rounded-square icon beside a single-line description.
/// Used on screens 2 and 3.
private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Decorative icon badge — description text is the full content. (A18-09)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            // Use the semantic .auraeBody token so the font scales with
            // Dynamic Type and matches the rest of the app. (REC-28)
            Text(description)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
    }
}

// MARK: - PermissionRow

/// Similar to FeatureRow but with a title + detail two-line layout.
/// Used on screen 5.
private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Decorative icon badge — title and detail carry the full content. (A18-09)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Text(detail)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("OnboardingView") {
    OnboardingView(onComplete: {})
}

#Preview("Screen 1 — Welcome") {
    WelcomePage(onNext: {})
        .background(Color.auraeAdaptiveBackground)
}

#Preview("Screen 5 — Permissions") {
    PermissionsPage(onComplete: {})
        .background(Color.auraeAdaptiveBackground)
}
