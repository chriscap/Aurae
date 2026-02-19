//
//  RetrospectiveEntry.swift
//  Aurae
//
//  SwiftData model capturing the post-headache retrospective detail the user
//  fills in after a headache resolves. All fields are optional — the user may
//  skip any or all sections.
//
//  Array fields (meals, symptoms, environmentalTriggers) are stored internally
//  as pipe-delimited strings (`|`) and exposed through typed Swift array
//  accessors. This avoids SwiftData Transformable registration complexity while
//  remaining fully testable and queryable.
//
//  Decision: pipe `|` is used as the delimiter rather than comma because food
//  descriptions may naturally contain commas.
//

import Foundation
import SwiftData

@Model
final class RetrospectiveEntry {

    // MARK: - Food & Drink

    /// Pipe-delimited list of meal descriptions or trigger shortcuts entered by
    /// the user (e.g. "aged cheese|chocolate|skipped lunch").
    /// Access via `meals` computed property.
    private var _meals: String

    /// Alcoholic drink type or "none". Nil if the user did not fill this field.
    var alcohol: String?

    /// Estimated caffeine intake in milligrams. Nil if not recorded.
    var caffeineIntake: Int?

    /// Number of glasses of water consumed. Nil if not recorded.
    var hydrationGlasses: Int?

    /// Whether the user skipped a meal before onset.
    var skippedMeal: Bool

    // MARK: - Lifestyle

    /// Sleep duration the previous night in hours. Nil if not manually entered
    /// and not auto-filled from HealthKit.
    var sleepHours: Double?

    /// Subjective sleep quality rated 1 (poor) – 5 (excellent).
    var sleepQuality: Int?

    /// Subjective stress level at time of onset, 1 (none) – 5 (extreme).
    var stressLevel: Int?

    /// Estimated screen time on the day of onset, in hours.
    var screenTimeHours: Double?

    // MARK: - Medication

    /// Name of the medication taken (e.g. "Ibuprofen", "Sumatriptan").
    var medicationName: String?

    /// Dose taken as a free-text string (e.g. "400 mg", "50 mg").
    var medicationDose: String?

    /// How effective the medication was, 1 (no effect) – 5 (complete relief).
    var medicationEffectiveness: Int?

    // MARK: - Symptoms

    /// Pipe-delimited list of symptoms experienced during the headache.
    /// Valid shorthand values: "nausea", "light_sensitivity", "sound_sensitivity",
    /// "aura", "neck_pain", "visual_disturbance", "vomiting", "dizziness".
    /// Access via `symptoms` computed property.
    private var _symptoms: String

    /// Free-text description of where the headache was felt (e.g. "left temple",
    /// "behind eyes", "whole head").
    var headacheLocation: String?

    /// Headache type classification chosen by the user.
    /// Valid values: "tension", "migraine", "cluster", "sinus", "other", "unknown".
    var headacheType: String?

    // MARK: - Women's Health

    /// Menstrual cycle phase at onset. Auto-filled from HealthKit when available.
    /// Valid values: "menstrual", "follicular", "ovulatory", "luteal", "unknown".
    var cyclePhase: String?

    // MARK: - Environment

    /// Pipe-delimited list of environmental trigger factors noted by the user.
    /// Valid shorthand values: "strong_smell", "bright_light", "loud_noise",
    /// "screen_glare", "weather_change", "altitude", "heat", "cold".
    /// Access via `environmentalTriggers` computed property.
    private var _environmentalTriggers: String

    /// Free-text notes the user adds to the retrospective entry.
    var notes: String?

    // MARK: - Metadata

    /// When this retrospective entry was last saved/updated.
    var updatedAt: Date

    // MARK: - Init

    init(
        meals: [String] = [],
        alcohol: String? = nil,
        caffeineIntake: Int? = nil,
        hydrationGlasses: Int? = nil,
        skippedMeal: Bool = false,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        stressLevel: Int? = nil,
        screenTimeHours: Double? = nil,
        medicationName: String? = nil,
        medicationDose: String? = nil,
        medicationEffectiveness: Int? = nil,
        symptoms: [String] = [],
        headacheLocation: String? = nil,
        headacheType: String? = nil,
        cyclePhase: String? = nil,
        environmentalTriggers: [String] = [],
        notes: String? = nil,
        updatedAt: Date = .now
    ) {
        self._meals                  = meals.joined(separator: "|")
        self.alcohol                 = alcohol
        self.caffeineIntake          = caffeineIntake
        self.hydrationGlasses        = hydrationGlasses
        self.skippedMeal             = skippedMeal
        self.sleepHours              = sleepHours
        self.sleepQuality            = sleepQuality
        self.stressLevel             = stressLevel
        self.screenTimeHours         = screenTimeHours
        self.medicationName          = medicationName
        self.medicationDose          = medicationDose
        self.medicationEffectiveness = medicationEffectiveness
        self._symptoms               = symptoms.joined(separator: "|")
        self.headacheLocation        = headacheLocation
        self.headacheType            = headacheType
        self.cyclePhase              = cyclePhase
        self._environmentalTriggers  = environmentalTriggers.joined(separator: "|")
        self.notes                   = notes
        self.updatedAt               = updatedAt
    }
}

// MARK: - Array accessors

extension RetrospectiveEntry {

    /// The list of meals / food triggers the user logged.
    var meals: [String] {
        get { splitPipeString(_meals) }
        set { _meals = newValue.joined(separator: "|") }
    }

    /// The list of symptoms experienced during the headache.
    var symptoms: [String] {
        get { splitPipeString(_symptoms) }
        set { _symptoms = newValue.joined(separator: "|") }
    }

    /// The list of environmental trigger factors noted by the user.
    var environmentalTriggers: [String] {
        get { splitPipeString(_environmentalTriggers) }
        set { _environmentalTriggers = newValue.joined(separator: "|") }
    }

    private func splitPipeString(_ value: String) -> [String] {
        value.isEmpty ? [] : value.split(separator: "|", omittingEmptySubsequences: true).map(String.init)
    }
}

// MARK: - Canonical value sets

extension RetrospectiveEntry {

    /// All valid symptom shorthand keys the UI should use.
    static let validSymptoms: [String] = [
        "nausea", "light_sensitivity", "sound_sensitivity",
        "aura", "neck_pain", "visual_disturbance", "vomiting", "dizziness"
    ]

    /// All valid environmental trigger shorthand keys the UI should use.
    static let validEnvironmentalTriggers: [String] = [
        "strong_smell", "bright_light", "loud_noise",
        "screen_glare", "weather_change", "altitude", "heat", "cold"
    ]

    /// All valid headache type values.
    static let validHeadacheTypes: [String] = [
        "tension", "migraine", "cluster", "sinus", "other", "unknown"
    ]

    /// All valid menstrual cycle phase values.
    static let validCyclePhases: [String] = [
        "menstrual", "follicular", "ovulatory", "luteal", "unknown"
    ]

    /// Common food trigger shortcuts shown as quick-select chips in the UI.
    static let foodTriggerShortcuts: [String] = [
        "aged cheese", "processed meat", "MSG", "citrus", "chocolate",
        "red wine", "caffeine", "artificial sweetener", "gluten"
    ]
}

// MARK: - Completeness helpers

extension RetrospectiveEntry {

    /// Returns true if the user has filled in at least one non-default field.
    var hasAnyData: Bool {
        !meals.isEmpty
            || alcohol != nil
            || caffeineIntake != nil
            || sleepHours != nil
            || stressLevel != nil
            || medicationName != nil
            || !symptoms.isEmpty
            || headacheType != nil
            || !environmentalTriggers.isEmpty
            || notes != nil
    }

    /// Progress fraction 0–1 representing how complete the retrospective is.
    /// Used to display the completion ring in the history list card.
    var completionFraction: Double {
        let fields: [Bool] = [
            !meals.isEmpty,
            alcohol != nil,
            caffeineIntake != nil,
            sleepHours != nil,
            sleepQuality != nil,
            stressLevel != nil,
            medicationName != nil,
            !symptoms.isEmpty,
            headacheType != nil,
            headacheLocation != nil,
            !environmentalTriggers.isEmpty
        ]
        let filled = fields.filter { $0 }.count
        return Double(filled) / Double(fields.count)
    }
}
