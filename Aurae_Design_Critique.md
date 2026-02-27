# Design Critique: Aurae iOS App

## Overall Impression

Aurae has a strong foundation — the "Dark Matter" palette feels premium and calming, the design system is well-tokenised, and there's clearly been careful thought given to the logging experience. The biggest opportunity is tightening consistency across secondary screens (Retrospective, Export, Onboarding) which haven't received the same polish as the Home screen, and addressing a handful of accessibility gaps that could affect real-world usability for migraine sufferers.

---

## Usability

| Finding | Severity | Recommendation |
|---------|----------|----------------|
| **Onset speed section starts at 25% opacity and is non-interactive until severity is touched.** Users who instinctively scroll past severity to onset speed will think the control is broken or disabled. | **Critical** | Replace opacity fade with a gentle prompt ("Select severity first") or make onset speed always interactive — the current pattern punishes exploration. At minimum, add VoiceOver guidance explaining why the control is disabled. |
| **Sequential disclosure has no visual cue.** The onset speed section just appears more opaque after severity interaction — there's no label, arrow, or animation telling the user "now answer this." | **Moderate** | Add a brief animated transition (e.g., a subtle slide-up or a "Next:" label above the onset speed section) to create a clear cause-and-effect relationship. |
| **Swipe-to-delete on History cards does nothing.** The code includes `.swipeActions` but the view uses `ScrollView + LazyVStack`, not `List` — so swipe gestures silently fail. Users must discover the context menu instead. | **Critical** | Either switch to `List` to enable native swipe actions, or remove the `.swipeActions` modifier and surface delete through a visible affordance (trailing icon button or long-press instruction). |
| **"Not sure" onset speed option resets selection to nil.** This is correct behaviour, but visually the "Not sure" pill appears pre-selected on first load (because `selected == nil` is true). A first-time user might think they've already answered. | **Moderate** | Distinguish "nothing selected yet" from "actively chose Not sure" — e.g., use a separate `hasInteracted` flag, or start with all pills unselected and only apply the selected style after a tap. |
| **LogConfirmation auto-dismisses in 2 seconds.** For a user in pain with reduced cognitive bandwidth, 2 seconds may not be enough to read the confirmation text, especially at high severity. | **Moderate** | Increase to 3–4 seconds, or let the user tap anywhere to dismiss early. The PRD says "calm confirmation animation" — rushing it contradicts that intent. |
| **Retrospective form has no progress indicator in the scroll area.** The toolbar `CompletionRing` is small (28pt) and can be missed. Users filling in a long form don't know how much is left. | **Minor** | Add a textual progress hint below the nav bar (e.g., "2 of 4 sections complete") or make the completion ring larger and more prominent. |
| **Export date range pickers have no quick-select shortcuts.** Users who want "Last 30 days" or "Last 3 months" must manually adjust two date pickers. | **Moderate** | Add preset chips ("Last 30 days", "Last 3 months", "All time") above the date pickers — this is standard in clinical export tools. |
| **Tab bar fourth tab is labelled "Export" but its enum case is `.settings`.** This is a code smell that could cause confusion during development and testing. | **Minor** | Rename the enum case to `.export` to match the user-facing label. |

---

## Visual Hierarchy

**What draws the eye first on the Home screen:** The days-free numeral (44pt `auraeDisplay`) dominates correctly, followed by the hero Log Headache button. This is good — the two most important elements (status and action) lead.

**Reading flow:** Header greeting → days-free count → activity strip → ambient triptych → severity pills → onset speed → Log Headache button. The flow is mostly top-to-bottom, but the ambient triptych card (weather, sleep, days free) competes with the severity selector for attention because both use bold numerals and similar card treatments.

**Emphasis concerns:**

| Element | Issue | Recommendation |
|---------|-------|----------------|
| Ambient triptych card and severity section are visually equal weight. | The triptych is informational context; severity is the primary input. They shouldn't compete. | Reduce the triptych's visual weight — use smaller numerals (18pt instead of 20pt), or move it below the fold / into a collapsible area. |
| InsightCard titles use `auraeSectionLabel` (17pt Fraunces) with `auraeTextSecondary` colour. | On the dark background, the secondary text colour can make these feel subdued — the titles don't anchor the cards strongly enough. | Consider using `auraeTextPrimary` for InsightCard titles or adding a subtle accent (e.g., a small teal leading rule). |
| The active headache banner uses `auraeAdaptiveBlush` background with a 3pt left accent bar. | This is well done — the colour shift and accent bar clearly communicate "something is happening." | No change needed — this is a highlight of the design. |
| Onboarding uses `.jakarta(28, weight: .semibold)` for headlines. | This breaks from the design system's Fraunces-for-headings convention and makes onboarding feel like a different app. | Switch to Fraunces for onboarding headlines to maintain brand continuity. |

---

## Consistency

| Element | Issue | Recommendation |
|---------|-------|----------------|
| **Card backgrounds mix `Color(.systemBackground)` and `Color.auraeAdaptiveCard`** | `RetroSectionContainer` uses `Color(.systemBackground).opacity(0.9)`, while `InsightCard` and `LogCard` correctly use `auraeAdaptiveCard`. Onboarding's `FeatureRow` and `PermissionRow` also use `Color(.systemBackground)`. | Replace all `Color(.systemBackground)` in card contexts with `auraeAdaptiveCard` for consistent dark-mode rendering. |
| **Two different shadow systems** | `LogCard` uses a custom two-layer shadow (ambient + key) with hardcoded hex colours, while every other card uses the shared `Layout.cardShadowOpacity / cardShadowRadius / cardShadowY` system. | Unify `LogCard` to use the shared Layout shadow tokens, or extract the two-layer system into Layout constants and apply it globally. |
| **ChipGrid selected state uses `Color.auraeTeal` fill** | This is the raw brand teal, but the severity pills use `severityPillFill(for:)` and the onset speed pills use `auraeAdaptiveSoftTeal`. Three different "selected" treatments across similar pill/chip components. | Standardise on one chip-selected treatment across the app — `auraeAdaptiveSoftTeal` fill with `auraeTealAccessible` text is the most accessible option. |
| **`Color.auraeNavy` used directly as text colour in Retrospective components** | Most of the app uses `auraeAdaptivePrimaryText` or `auraeTextPrimary` (which adapt to dark mode), but `RetroSectionContainer`, `RetroStarRating`, `RetroStepper`, and `ChipGrid` all use raw `Color.auraeNavy`. In the forced-dark scheme, navy (#0D1B2A) on a dark card surface could have insufficient contrast. | Replace `Color.auraeNavy` with `Color.auraeAdaptivePrimaryText` in all Retrospective components. |
| **Section spacing inconsistency** | `RetrospectiveView` uses `Layout.itemSpacing` between sections, while `HomeView` uses `Layout.sectionSpacing`. The Retrospective sections are visually cramped by comparison. | Use `Layout.sectionSpacing` between major sections in RetrospectiveView. |
| **Button label fonts** | The hero Log Headache button uses Fraunces SemiBold 19pt, the standard `.primary` AuraeButton uses Jakarta SemiBold 16pt, and onboarding buttons also use `.primary`. The font family shift between hero and non-hero buttons is intentional but could feel jarring on the same screen. | Consider whether all CTA buttons should use Jakarta for consistency, reserving Fraunces purely for display/heading contexts. |

---

## Accessibility

| Finding | Severity | Recommendation |
|---------|----------|----------------|
| **Onset speed section blocked from touch (`allowsHitTesting(false)`) with no VoiceOver explanation.** | **Critical** | When `hasInteractedWithSeverity` is false, VoiceOver users will encounter the onset speed pills but be unable to interact with them, with no explanation why. Add `.accessibilityHint("Select a severity level first to enable this control")` and consider making the entire section `.accessibilityHidden(true)` until it becomes interactive. |
| **`RetroSectionContainer` header uses `Color.auraeNavy` for the title.** In forced-dark mode, navy (#0D1B2A) on a dark card (~#131420) yields a contrast ratio of approximately 1.2:1 — far below WCAG AA (4.5:1). | **Critical** | Switch to `Color.auraeAdaptivePrimaryText` which resolves to `auraeStarlight` (#E8E6F0) in dark mode. |
| **Sublabel opacity in OnsetSpeedPill:** `auraeTextSecondary.opacity(0.70)` for unselected sublabels further reduces already-moderate contrast.** | **Moderate** | Remove the opacity reduction on sublabels, or ensure the resulting colour passes WCAG AA (4.5:1) against `auraeAdaptiveSecondary`. |
| **`hintText` in LogConfirmationView uses `Color.auraeMidGray.opacity(0.7)`.** On the navy overlay (#0D1B2A at 82% opacity), this produces very low contrast. The hint contains actionable guidance ("Consider taking medication now"). | **Moderate** | Use `Color.auraeMidGray` without opacity reduction, or use `auraeTextSecondary` to ensure the severity-aware hints are readable. |
| **Star rating in `RetroStarRating` uses `Color.auraeMidGray.opacity(0.4)` for unselected stars.** | **Moderate** | Increase to `opacity(0.5)` minimum, or use `auraeAdaptiveSecondary` as the unselected star colour for better visibility. |
| **Dynamic Type: onset speed pill labels use fixed `jakarta(12)` with `lineLimit(1)` and `minimumScaleFactor(0.8)`.** At accessibility text sizes, the labels will shrink rather than reflow, making them potentially unreadable. | **Moderate** | Use `relativeTo:` parameter (e.g., `.jakarta(12, relativeTo: .caption)`) for the primary label, and consider allowing `lineLimit(2)` at larger accessibility sizes. |
| **No haptic feedback on the hero Log Headache button tap.** Severity pills and onset speed pills both trigger `UIImpactFeedbackGenerator`, but the most important button in the app has no tactile confirmation. | **Minor** | Add `.medium` impact feedback on the Log Headache button tap — this is especially important for users logging during a migraine when visual focus is impaired. |
| **WeekdayCell uses `jakarta(10)` for day abbreviations.** 10pt text at standard Dynamic Type is already small; at the smallest accessibility size it becomes illegible. | **Minor** | Use `jakarta(11, relativeTo: .caption2)` minimum, matching the fix already applied to onset speed sublabels. |
| **CalendarView not audited** — no `.accessibilityLabel` or `.accessibilityValue` visible in the HistoryView file for calendar cells. | **Moderate** | Ensure each calendar day cell has a label like "February 15, 2 headaches, average severity 3" for VoiceOver users. |

---

## What Works Well

The **severity pill redesign** (fill-based, with carefully computed WCAG-passing colours) is excellent — it's one of the most visually polished components in the app. The graduated severity colour system (`severityAccent`, `severitySurface`, `severityPillFill`) creates a clear and intuitive visual language.

The **Dark Matter palette** successfully achieves a premium, calming aesthetic. The near-black background (#0D0E11) with violet bloom and teal wash creates genuine atmospheric depth without feeling heavy. This is unusually well-executed for a health app.

The **safety system** (RedFlagBannerCard, MedicalEscalationView, per-log acknowledgement tracking) is thoughtfully designed. The two urgency tiers, clinically reviewed copy, and persistent-per-log dismiss state show real care for user wellbeing. The pattern of showing the banner at multiple touchpoints (LogConfirmation, HomeView, InsightsView) without being intrusive is well balanced.

The **LogCard component** is a standout — the severity accent bar, two-layer shadow, subtle severity surface wash, and context chips create a rich but readable card. The VoiceOver description is comprehensive.

The **Retrospective completion ring** in the toolbar is a nice touch that encourages thoroughness without pressuring the user.

**Reduce Motion support** is consistently applied across animations (severity pills, onset speed pills, log confirmation, section expand/collapse). This is above average for iOS apps.

---

## Priority Recommendations

### 1. Fix dark-mode contrast issues in Retrospective components

**Why:** Multiple components use `Color.auraeNavy` directly as text colour. In the forced-dark scheme, this creates near-invisible text on dark card surfaces. This affects every user in the current "dark-first" configuration.

**How:** Search-and-replace `Color.auraeNavy` with `Color.auraeAdaptivePrimaryText` in `RetroSectionContainer`, `RetroStarRating`, `RetroStepper`, `RetroStepperDouble`, `RetroTextField`, `ChipGrid`, and `SingleSelectPillGroup`. Also replace `Color(.systemBackground)` card backgrounds with `Color.auraeAdaptiveCard`.

### 2. Make the onset speed sequential disclosure accessible

**Why:** The current implementation (25% opacity + `allowsHitTesting(false)`) creates a completely invisible barrier for VoiceOver users and a confusing experience for sighted users who scroll past severity.

**How:** Either (a) make onset speed always interactive and remove the disclosure pattern, or (b) hide the section from VoiceOver entirely when disabled and add a visible "Select severity to continue" label that appears when the user scrolls to or focuses on the onset speed area.

### 3. Unify card background and shadow tokens

**Why:** Three different card background approaches (`systemBackground`, `auraeAdaptiveCard`, `systemBackground.opacity(0.9)`) and two shadow systems create subtle visual inconsistencies that undermine the premium feel.

**How:** Audit every card-style component and standardise on `auraeAdaptiveCard` for backgrounds and the shared `Layout.cardShadow*` tokens for shadows. Extract `LogCard`'s two-layer shadow approach into Layout if it's the preferred system, and apply it everywhere.

### 4. Increase LogConfirmation display duration

**Why:** Users logging during a migraine attack have reduced cognitive bandwidth. A 2-second auto-dismiss may not allow them to read the severity-contextual hint or notice the red-flag banner.

**How:** Increase the base timer to 3.5 seconds. Add a tap-to-dismiss gesture so users who are feeling well can skip it. Keep the red-flag banner suppression logic as-is.

### 5. Add haptic feedback to the Log Headache button

**Why:** This is the single most important interaction in the app. Every other tappable control (severity pills, onset speed pills, chips, stars) has haptic feedback except this one. During a migraine, users may be logging with eyes partially closed — tactile confirmation that the tap registered is essential.

**How:** Add `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` to the Log Headache button action handler. Use `.medium` (not `.light`) to match the significance of the action.
