//
//  FirstInsightsView.swift
//  Aurae
//
//  One-time educational interstitial shown when the user reaches 5 resolved
//  logs and navigates to the Insights tab for the first time.
//
//  D-27 (22 Feb 2026): This screen is an educational gate — not a paywall.
//  It sets accurate expectations about co-occurrence vs. causation and
//  prompts the user to discuss findings with their clinician before they
//  see their first pattern analysis.
//
//  State persistence: @AppStorage("hasSeenFirstInsights"). Written to true
//  when the user taps "Got it — show my patterns."
//
//  Presentation: fullScreenCover from InsightsView.
//

import SwiftUI

// MARK: - FirstInsightsView

struct FirstInsightsView: View {

    @AppStorage("hasSeenFirstInsights") private var hasSeenFirstInsights: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.auraeAdaptiveBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {

                    // Decorative icon — warmth and data, not alarm.
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.auraeAdaptiveSoftTeal)
                                .frame(width: 80, height: 80)
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(Color.auraeTealAccessible)
                        }
                        Spacer()
                    }
                    .accessibilityHidden(true)
                    .padding(.top, Layout.sectionSpacing)

                    // Title
                    Text("Your first patterns")
                        .font(.auraeDisplay)
                        .foregroundStyle(Color.auraeTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Three educational paragraphs (D-27 required content)
                    VStack(alignment: .leading, spacing: Layout.itemSpacing) {

                        ParagraphBlock(
                            icon: "1.circle.fill",
                            text: "The more you log, the more reliable your patterns become. With just a few entries, what you see are early signals — not conclusions."
                        )

                        ParagraphBlock(
                            icon: "2.circle.fill",
                            text: "Aurae looks for factors that appear frequently before your headaches. These are patterns worth noticing, not proven causes."
                        )

                        ParagraphBlock(
                            icon: "3.circle.fill",
                            text: "Bring these patterns to your next healthcare appointment. Your clinician can help you understand what they mean for you."
                        )
                    }

                    // Spacer to clear the sticky button
                    Spacer(minLength: Layout.buttonHeight + Layout.sectionSpacing)
                }
                .padding(.horizontal, Layout.screenPadding)
            }

            // Sticky CTA
            VStack {
                Spacer()
                ctaBar
            }
        }
        .overlay(alignment: .topTrailing) {
            // Close button — fullScreenCover has no navigation bar, so we
            // provide a manual dismiss affordance in the top-trailing corner.
            Button {
                hasSeenFirstInsights = true
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.auraeMidGray)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            }
            .accessibilityLabel("Close")
            .padding(.top, 8)
            .padding(.trailing, Layout.screenPadding)
        }
    }

    // MARK: - CTA bar

    private var ctaBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.auraeAdaptiveBackground.opacity(0), Color.auraeAdaptiveBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            AuraeButton("Got it — show my patterns") {
                hasSeenFirstInsights = true
                dismiss()
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, Layout.itemSpacing)
            .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - ParagraphBlock

/// Numbered icon + body copy pair. Keeps the layout clean and accessible.
private struct ParagraphBlock: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.auraeTeal)
                .frame(width: 28, alignment: .center)
                // Icon is purely decorative enumeration — numbered text conveys order.
                .accessibilityHidden(true)

            Text(text)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0,
            y: Layout.cardShadowY
        )
    }
}

// MARK: - Preview

#Preview("FirstInsightsView") {
    FirstInsightsView()
}
