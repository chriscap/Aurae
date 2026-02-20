//
//  AuraeButton.swift
//  Aurae
//
//  Primary CTA button used throughout Aurae. Renders with the brand Teal fill,
//  a Fraunces label, 56 pt fixed height, and spring-physics press animation.
//  Provides haptic feedback on tap and respects Reduce Motion preferences.
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
    /// Teal filled — primary CTA. Use for the single most important action per screen.
    case primary
    /// Outlined teal — secondary action. Use when a second CTA is necessary.
    case secondary
    /// Destructive red-tinted outline — for delete / irreversible actions.
    case destructive
}

// MARK: - AuraeButton

struct AuraeButton: View {

    let title: String
    var style: AuraeButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ title: String, style: AuraeButtonStyle = .primary, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    // Resolved colours per style
    private var fillColor: Color {
        switch style {
        case .primary:     return .auraeTeal
        case .secondary:   return .clear
        case .destructive: return .clear
        }
    }

    private var labelColor: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .auraeTeal
        case .destructive: return Color(hex: "B03A2E")
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:     return .clear
        case .secondary:   return .auraeTeal
        case .destructive: return Color(hex: "B03A2E")
        }
    }

    private var pressedScale: CGFloat {
        reduceMotion ? 1.0 : 0.97
    }

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            feedbackGenerator.impactOccurred()
            action()
        } label: {
            ZStack {
                // Background fill
                RoundedRectangle(cornerRadius: Layout.buttonRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.buttonRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )

                // Label / spinner
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(labelColor)
                } else {
                    Text(title)
                        // Primary CTAs use Fraunces for brand weight.
                        // Secondary/destructive use Jakarta so they read
                        // as supporting actions, not competing headlines.
                        .font(style == .primary
                              ? .fraunces(18, weight: .bold, relativeTo: .body)
                              : .jakarta(16, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? pressedScale : 1.0)
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading, please wait." : "")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.08)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                }
        )
    }
}

// MARK: - Preview

#Preview("AuraeButton variants") {
    @Previewable @State var isLoading = false

    VStack(spacing: 16) {
        AuraeButton("Log Headache") { isLoading.toggle() }
        AuraeButton("Log Headache", isLoading: true) {}
        AuraeButton("View Insights", style: .secondary) {}
        AuraeButton("Delete All Data", style: .destructive) {}
        AuraeButton("Log Headache", isDisabled: true) {}
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeBackground)
}
