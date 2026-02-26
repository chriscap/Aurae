//
//  AuraeButton.swift
//  Aurae
//
//  Primary CTA button used throughout Aurae.
//  Updated 2026-02-25 to "Calm Blue" direction:
//  - Primary: blue gradient + 20% black accessibility overlay, white label
//  - Hero: same as primary (gradient + overlay), 56pt height
//  - Secondary: outlined blue border
//  - Destructive: destructive red outline
//
//  The 20% black overlay on gradient backgrounds is REQUIRED for text contrast
//  per the design system accessibility spec.
//
//  Usage:
//  ```swift
//  AuraeButton("Log Headache") { logHeadache() }
//  AuraeButton("Log Headache", isLoading: isCapturing) { logHeadache() }
//  AuraeButton("Export PDF", style: .secondary) { export() }
//  ```
//

import SwiftUI

// MARK: - Button style variants

enum AuraeButtonStyle {
    /// Primary gradient CTA — full-width blue gradient with white label.
    case primary
    /// Hero CTA — same as primary but used for the Log Headache action.
    case hero
    /// Outlined blue — secondary action.
    case secondary
    /// Destructive red outline — for delete / irreversible actions.
    case destructive
}

// MARK: - AuraeButton

struct AuraeButton: View {

    let title: String
    var style: AuraeButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ title: String,
         style: AuraeButtonStyle = .primary,
         isLoading: Bool = false,
         isDisabled: Bool = false,
         action: @escaping () -> Void) {
        self.title     = title
        self.style     = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action    = action
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private var buttonHeight: CGFloat { Layout.buttonHeight }
    private var cornerRadius: CGFloat { AuraeRadius.md }

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            feedbackGenerator.impactOccurred()
            action()
        } label: {
            ZStack {
                buttonBackground

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(labelColor)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(
            color: shadowColor,
            radius: 20, x: 0, y: 8
        )
        .scaleEffect(isPressed ? (reduceMotion ? 1.0 : 0.97) : 1.0)
        .opacity(isDisabled ? 0.5 : (reduceMotion && isPressed ? 0.75 : 1.0))
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading, please wait." : "")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.08)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.20)) { isPressed = false }
                }
        )
    }

    // MARK: Appearance

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary, .hero:
            ZStack {
                // Blue gradient
                LinearGradient(
                    colors: [Color(hex: "5B8EBF"), Color(hex: "7BA8D1")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                // REQUIRED: 20% black overlay for WCAG AA text contrast on gradient
                Color.black.opacity(0.20)
            }
        case .secondary:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.auraePrimary, lineWidth: 1.5)
                )
        case .destructive:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.auraeDestructive, lineWidth: 1.5)
                )
        }
    }

    private var labelColor: Color {
        switch style {
        case .primary, .hero: return .white
        case .secondary:      return Color.auraePrimary
        case .destructive:    return Color.auraeDestructive
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary, .hero: return Color(hex: "5B8EBF").opacity(0.30)
        default:              return .clear
        }
    }
}

// MARK: - Preview

#Preview("AuraeButton variants") {
    @Previewable @State var isLoading = false

    VStack(spacing: 16) {
        AuraeButton("Log Headache", style: .hero) { isLoading.toggle() }
        AuraeButton("Log Headache", isLoading: true) {}
        AuraeButton("View Insights", style: .secondary) {}
        AuraeButton("Delete All Data", style: .destructive) {}
        AuraeButton("Log Headache", isDisabled: true) {}
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeAdaptiveBackground)
}
