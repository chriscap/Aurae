//
//  FoodDrinkSection.swift
//  Aurae
//
//  Collapsible Food & Drink section for the retrospective entry screen.
//
//  Controls:
//  - Multi-select chip grid: meal triggers (Coffee, Tea, Alcohol, etc.)
//  - Conditional alcohol detail text field (visible when Alcohol chip selected)
//  - Caffeine intake stepper (0–800 mg, step 50)
//  - Hydration stepper (0–20 glasses)
//  - Skipped meal toggle
//

import SwiftUI

struct FoodDrinkSection: View {

    @Binding var selectedMeals: Set<String>
    @Binding var alcoholDetail: String
    @Binding var caffeineIntakeMg: Int
    @Binding var hydrationGlasses: Int
    @Binding var skippedMeal: Bool
    let hasData: Bool

    @State private var isExpanded: Bool = true

    var body: some View {
        RetroSectionContainer(
            title: "Food & Drink",
            hasData: hasData,
            isExpanded: $isExpanded
        ) {
            // Meal trigger chips
            ChipGrid(
                items: RetrospectiveViewModel.mealChips,
                selected: $selectedMeals
            )

            // Alcohol detail field — slides in when Alcohol chip is selected
            if selectedMeals.contains("Alcohol") {
                RetroTextField(
                    placeholder: "Type of drink (optional)",
                    text: $alcoholDetail
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Caffeine stepper
            RetroStepper(
                label: "Caffeine",
                unit: "mg",
                value: $caffeineIntakeMg,
                range: 0...800,
                step: 50,
                formatValue: { "\($0) mg" }
            )

            // Hydration stepper
            RetroStepper(
                label: "Water",
                unit: "glasses",
                value: $hydrationGlasses,
                range: 0...20,
                step: 1,
                formatValue: { $0 == 1 ? "1 glass" : "\($0) glasses" }
            )

            // Skipped meal toggle
            RetroToggleRow(label: "Skipped a meal", isOn: $skippedMeal)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMeals.contains("Alcohol"))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var meals: Set<String> = ["Coffee", "Alcohol"]
    @Previewable @State var alcohol: String = "Red wine"
    @Previewable @State var caffeine: Int = 200
    @Previewable @State var hydration: Int = 4
    @Previewable @State var skipped: Bool = false

    ScrollView {
        FoodDrinkSection(
            selectedMeals:   $meals,
            alcoholDetail:   $alcohol,
            caffeineIntakeMg: $caffeine,
            hydrationGlasses: $hydration,
            skippedMeal:     $skipped,
            hasData:         true
        )
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeAdaptiveBackground)
}
