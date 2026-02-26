//
//  RetrospectiveViewModel.swift
//  Aurae
//
//  Owns all mutable form state for the retrospective entry screen and handles
//  persistence. Designed to be instantiated once per HeadacheLog per screen
//  presentation — the log and context are injected at init time.
//
//  Architecture notes:
//  - @Observable @MainActor: all stored properties drive SwiftUI re-renders
//    automatically on the main actor.
//  - Pre-population: if the log already has a RetrospectiveEntry (user is
//    editing a previously saved entry), all fields are seeded from it.
//  - HealthKit pre-population: sleepHours is seeded from the log's
//    HealthSnapshot if available and the retrospective has no sleep data yet.
//  - hasUnsavedChanges: compared against the snapshot taken at init time so
//    the discard confirmation only appears when something actually changed.
//  - save(): creates or updates the RetrospectiveEntry in-place and saves the
//    ModelContext. Does not dismiss — the view handles dismissal.
//

import SwiftUI
import SwiftData

// MARK: - Chip item

/// A selectable chip option pairing a user-visible label with the canonical
/// model key stored in the pipe-delimited backing string.
struct ChipItem: Identifiable, Equatable {
    let id: String   // canonical model key
    let label: String
}

// MARK: - RetrospectiveViewModel

@Observable
@MainActor
final class RetrospectiveViewModel {

    // =========================================================================
    // MARK: - Food & Drink state
    // =========================================================================

    /// Currently selected meal chips (stored by canonical id / label).
    /// For meals the canonical id == label (free-form strings in the model).
    var selectedMeals: Set<String> = []

    /// Text field value for alcohol description — only visible when "Alcohol"
    /// chip is selected.
    var alcoholDetail: String = ""

    /// Caffeine intake in mg (stepper, 0–800, step 50).
    var caffeineIntakeMg: Int = 0

    /// Glasses of water (stepper, 0–20, step 1).
    var hydrationGlasses: Int = 0

    /// Whether the user skipped a meal.
    var skippedMeal: Bool = false

    // =========================================================================
    // MARK: - Lifestyle state
    // =========================================================================

    /// Sleep duration slider (0–12h, step 0.5h).
    var sleepHours: Double = 7.0

    /// Whether a sleep hours value has been explicitly set (either pre-populated
    /// from HealthKit or changed by the user). Guards the "auto-filled" badge.
    var sleepHoursSet: Bool = false

    /// Whether sleep was pre-filled from HealthKit.
    var sleepPrefilledFromHealth: Bool = false

    /// Subjective sleep quality (1–5 stars).
    var sleepQuality: Int = 0

    /// Stress level (1–5 picker).
    var stressLevel: Int = 0

    /// Screen time in hours (stepper, 0–16h, step 0.5h).
    var screenTimeHours: Double = 0.0

    // =========================================================================
    // MARK: - Medication state
    // =========================================================================

    var medicationName: String = ""
    var medicationDose: String = ""

    /// Effectiveness rating (1–5 stars).
    var medicationEffectiveness: Int = 0

    /// D-32: Acute vs preventive classification. nil = not yet classified.
    var medicationIsAcute: Bool? = nil

    // =========================================================================
    // MARK: - Environment / Symptoms state
    // =========================================================================

    /// Selected environmental trigger canonical keys.
    var selectedTriggers: Set<String> = []

    /// Selected symptom canonical keys.
    var selectedSymptoms: Set<String> = []

    /// Selected headache location raw string.
    var headacheLocation: String = ""

    /// Selected headache type canonical string.
    var headacheType: String = ""

    /// Selected cycle phase canonical string ("" means not set).
    var cyclePhase: String = ""

    /// Free-text notes.
    var notes: String = ""

    // =========================================================================
    // MARK: - UI state
    // =========================================================================

    var isSaving: Bool = false
    var saveError: String? = nil

    // =========================================================================
    // MARK: - Private
    // =========================================================================

    private let log: HeadacheLog
    private let context: ModelContext

    /// Snapshot of all fields taken at init — used by hasUnsavedChanges.
    private let initialSnapshot: FormSnapshot

    /// True when the log already had a RetrospectiveEntry when this view model
    /// was created. Used by RetrospectiveView to suppress the "No changes to
    /// save yet." hint on first open of a brand-new retrospective.
    let hadExistingRetrospectiveOnEntry: Bool

    // =========================================================================
    // MARK: - Init
    // =========================================================================

    init(log: HeadacheLog, context: ModelContext) {
        // ── Step 1: collect all field values into locals ──────────────────────
        // Swift 6 requires every stored property to be initialized before
        // `self` is accessed. We compute everything into locals first, then
        // assign all stored properties in a single pass, then set the
        // initialSnapshot using those same locals.

        var _selectedMeals:            Set<String> = []
        var _alcoholDetail:            String       = ""
        var _caffeineIntakeMg:         Int          = 0
        var _hydrationGlasses:         Int          = 0
        var _skippedMeal:              Bool         = false
        var _sleepHours:               Double       = 7.0
        var _sleepHoursSet:            Bool         = false
        var _sleepPrefilledFromHealth: Bool         = false
        var _sleepQuality:             Int          = 0
        var _stressLevel:              Int          = 0
        var _screenTimeHours:          Double       = 0.0
        var _medicationName:           String       = ""
        var _medicationDose:           String       = ""
        var _medicationEffectiveness:  Int          = 0
        var _medicationIsAcute:        Bool?        = nil
        var _selectedTriggers:         Set<String>  = []
        var _selectedSymptoms:         Set<String>  = []
        var _headacheLocation:         String       = ""
        var _headacheType:             String       = ""
        var _cyclePhase:               String       = ""
        var _notes:                    String       = ""

        if let retro = log.retrospective {
            _selectedMeals           = Set(retro.meals)
            _alcoholDetail           = retro.alcohol ?? ""
            _caffeineIntakeMg        = retro.caffeineIntake ?? 0
            _hydrationGlasses        = retro.hydrationGlasses ?? 0
            _skippedMeal             = retro.skippedMeal
            _sleepQuality            = retro.sleepQuality ?? 0
            _stressLevel             = retro.stressLevel ?? 0
            _screenTimeHours         = retro.screenTimeHours ?? 0.0
            _medicationName          = retro.medicationName ?? ""
            _medicationDose          = retro.medicationDose ?? ""
            _medicationEffectiveness = retro.medicationEffectiveness ?? 0
            _medicationIsAcute       = retro.medicationIsAcute
            _selectedTriggers        = Set(retro.environmentalTriggers)
            _selectedSymptoms        = Set(retro.symptoms)
            _headacheLocation        = retro.headacheLocation ?? ""
            _headacheType            = retro.headacheType ?? ""
            _cyclePhase              = retro.cyclePhase ?? ""
            _notes                   = retro.notes ?? ""

            if let h = retro.sleepHours {
                _sleepHours    = h
                _sleepHoursSet = true
            }
        }

        // Pre-populate sleep from HealthKit if retrospective had no sleep value.
        if !_sleepHoursSet, let healthSleep = log.health?.sleepHours {
            _sleepHours               = healthSleep
            _sleepHoursSet            = true
            _sleepPrefilledFromHealth = true
        }

        // ── Step 2: assign all stored properties ──────────────────────────────
        self.log     = log
        self.context = context
        self.hadExistingRetrospectiveOnEntry = log.retrospective != nil

        self.selectedMeals            = _selectedMeals
        self.alcoholDetail            = _alcoholDetail
        self.caffeineIntakeMg         = _caffeineIntakeMg
        self.hydrationGlasses         = _hydrationGlasses
        self.skippedMeal              = _skippedMeal
        self.sleepHours               = _sleepHours
        self.sleepHoursSet            = _sleepHoursSet
        self.sleepPrefilledFromHealth = _sleepPrefilledFromHealth
        self.sleepQuality             = _sleepQuality
        self.stressLevel              = _stressLevel
        self.screenTimeHours          = _screenTimeHours
        self.medicationName           = _medicationName
        self.medicationDose           = _medicationDose
        self.medicationEffectiveness  = _medicationEffectiveness
        self.medicationIsAcute        = _medicationIsAcute
        self.selectedTriggers         = _selectedTriggers
        self.selectedSymptoms         = _selectedSymptoms
        self.headacheLocation         = _headacheLocation
        self.headacheType             = _headacheType
        self.cyclePhase               = _cyclePhase
        self.notes                    = _notes
        self.isSaving                 = false
        self.saveError                = nil

        // ── Step 3: initialSnapshot uses locals, not self ─────────────────────
        self.initialSnapshot = FormSnapshot(
            selectedMeals:            _selectedMeals,
            alcoholDetail:            _alcoholDetail,
            caffeineIntakeMg:         _caffeineIntakeMg,
            hydrationGlasses:         _hydrationGlasses,
            skippedMeal:              _skippedMeal,
            sleepHours:               _sleepHoursSet ? _sleepHours : nil,
            sleepQuality:             _sleepQuality,
            stressLevel:              _stressLevel,
            screenTimeHours:          _screenTimeHours,
            medicationName:           _medicationName,
            medicationDose:           _medicationDose,
            medicationEffectiveness:  _medicationEffectiveness,
            medicationIsAcute:        _medicationIsAcute,
            selectedTriggers:         _selectedTriggers,
            selectedSymptoms:         _selectedSymptoms,
            headacheLocation:         _headacheLocation,
            headacheType:             _headacheType,
            cyclePhase:               _cyclePhase,
            notes:                    _notes
        )
    }

    // =========================================================================
    // MARK: - Computed helpers
    // =========================================================================

    /// True when any form field differs from the snapshot taken at init.
    var hasUnsavedChanges: Bool {
        currentSnapshot != initialSnapshot
    }

    /// Fraction (0–1) of retrospective fields that have data.
    /// Mirrors RetrospectiveEntry.completionFraction logic for live preview.
    var completionFraction: Double {
        let flags: [Bool] = [
            !selectedMeals.isEmpty,
            !alcoholDetail.isEmpty,
            caffeineIntakeMg > 0,
            sleepHoursSet,
            sleepQuality > 0,
            stressLevel > 0,
            !medicationName.isEmpty,
            !selectedSymptoms.isEmpty,
            !headacheType.isEmpty,
            !headacheLocation.isEmpty,
            !selectedTriggers.isEmpty
        ]
        return Double(flags.filter { $0 }.count) / Double(flags.count)
    }

    // Section completion — used to show filled dot in section headers.
    var foodSectionHasData: Bool {
        !selectedMeals.isEmpty || !alcoholDetail.isEmpty || caffeineIntakeMg > 0
        || hydrationGlasses > 0 || skippedMeal
    }
    var lifestyleSectionHasData: Bool {
        sleepHoursSet || sleepQuality > 0 || stressLevel > 0 || screenTimeHours > 0
    }
    var medicationSectionHasData: Bool {
        !medicationName.isEmpty
    }
    var environmentSectionHasData: Bool {
        !selectedTriggers.isEmpty || !selectedSymptoms.isEmpty
        || !headacheLocation.isEmpty || !headacheType.isEmpty
        || !cyclePhase.isEmpty || !notes.isEmpty
    }

    // Whether to show the Alcohol detail text field.
    var alcoholChipSelected: Bool {
        selectedMeals.contains("Alcohol")
    }

    // =========================================================================
    // MARK: - Save
    // =========================================================================

    /// Creates or updates the RetrospectiveEntry on the log and saves the
    /// ModelContext. Returns true on success.
    @discardableResult
    func save() -> Bool {
        isSaving  = true
        saveError = nil

        let retro = log.retrospective ?? {
            let r = RetrospectiveEntry()
            log.retrospective = r
            context.insert(r)
            return r
        }()

        retro.meals                   = Array(selectedMeals)
        retro.alcohol                 = alcoholChipSelected && !alcoholDetail.isEmpty
                                            ? alcoholDetail : nil
        retro.caffeineIntake          = caffeineIntakeMg > 0 ? caffeineIntakeMg : nil
        retro.hydrationGlasses        = hydrationGlasses > 0 ? hydrationGlasses : nil
        retro.skippedMeal             = skippedMeal
        retro.sleepHours              = sleepHoursSet ? sleepHours : nil
        retro.sleepQuality            = sleepQuality > 0 ? sleepQuality : nil
        retro.stressLevel             = stressLevel > 0 ? stressLevel : nil
        retro.screenTimeHours         = screenTimeHours > 0 ? screenTimeHours : nil
        retro.medicationName          = medicationName.isEmpty ? nil : medicationName
        retro.medicationDose          = medicationDose.isEmpty ? nil : medicationDose
        retro.medicationEffectiveness = medicationEffectiveness > 0
                                            ? medicationEffectiveness : nil
        // D-32: Only persist classification when a medication name is present.
        retro.medicationIsAcute       = medicationName.isEmpty ? nil : medicationIsAcute
        retro.environmentalTriggers   = Array(selectedTriggers)
        retro.symptoms                = Array(selectedSymptoms)
        retro.headacheLocation        = headacheLocation.isEmpty ? nil : headacheLocation
        retro.headacheType            = headacheType.isEmpty ? nil : headacheType
        retro.cyclePhase              = cyclePhase.isEmpty ? nil : cyclePhase
        retro.notes                   = notes.isEmpty ? nil : notes
        retro.updatedAt               = .now
        log.updatedAt                 = .now

        do {
            try context.save()
            isSaving = false
            return true
        } catch {
            saveError = "Could not save. Please try again."
            isSaving  = false
            return false
        }
    }

    // =========================================================================
    // MARK: - Private helpers
    // =========================================================================

    private var currentSnapshot: FormSnapshot {
        FormSnapshot(
            selectedMeals:           selectedMeals,
            alcoholDetail:           alcoholDetail,
            caffeineIntakeMg:        caffeineIntakeMg,
            hydrationGlasses:        hydrationGlasses,
            skippedMeal:             skippedMeal,
            sleepHours:              sleepHoursSet ? sleepHours : nil,
            sleepQuality:            sleepQuality,
            stressLevel:             stressLevel,
            screenTimeHours:         screenTimeHours,
            medicationName:          medicationName,
            medicationDose:          medicationDose,
            medicationEffectiveness: medicationEffectiveness,
            medicationIsAcute:       medicationIsAcute,
            selectedTriggers:        selectedTriggers,
            selectedSymptoms:        selectedSymptoms,
            headacheLocation:        headacheLocation,
            headacheType:            headacheType,
            cyclePhase:              cyclePhase,
            notes:                   notes
        )
    }
}

// MARK: - FormSnapshot (value-type equality for change detection)

/// An equatable snapshot of all form fields used to detect unsaved changes.
/// All properties are value types — comparing two snapshots is O(n) but n is
/// small and this only runs on user interaction.
private struct FormSnapshot: Equatable {
    let selectedMeals: Set<String>
    let alcoholDetail: String
    let caffeineIntakeMg: Int
    let hydrationGlasses: Int
    let skippedMeal: Bool
    let sleepHours: Double?
    let sleepQuality: Int
    let stressLevel: Int
    let screenTimeHours: Double
    let medicationName: String
    let medicationDose: String
    let medicationEffectiveness: Int
    let medicationIsAcute: Bool?
    let selectedTriggers: Set<String>
    let selectedSymptoms: Set<String>
    let headacheLocation: String
    let headacheType: String
    let cyclePhase: String
    let notes: String
}

// MARK: - Canonical chip definitions

/// Meal chips: display label == stored value (meals are free-form strings).
extension RetrospectiveViewModel {
    static let mealChips: [ChipItem] = [
        ChipItem(id: "Coffee",         label: "Coffee"),
        ChipItem(id: "Tea",            label: "Tea"),
        ChipItem(id: "Alcohol",        label: "Alcohol"),
        ChipItem(id: "Chocolate",      label: "Chocolate"),
        ChipItem(id: "Cheese",         label: "Cheese"),
        ChipItem(id: "Processed food", label: "Processed food"),
        ChipItem(id: "Fast food",      label: "Fast food"),
        ChipItem(id: "Citrus",         label: "Citrus"),
        ChipItem(id: "Other",          label: "Other"),
    ]
}

/// Environmental trigger chips: id == canonical model key, label == display string.
extension RetrospectiveViewModel {
    static let triggerChips: [ChipItem] = [
        ChipItem(id: "bright_light",    label: "Bright light"),
        ChipItem(id: "loud_noise",      label: "Loud noise"),
        ChipItem(id: "strong_smell",    label: "Strong smell"),
        ChipItem(id: "screen_glare",    label: "Screen glare"),
        ChipItem(id: "weather_change",  label: "Weather change"),
        ChipItem(id: "altitude",        label: "Poor ventilation"),
        ChipItem(id: "heat",            label: "Smoke"),
        ChipItem(id: "cold",            label: "Other"),
    ]
}

/// Symptom chips: id == canonical model key, label == display string.
extension RetrospectiveViewModel {
    static let symptomChips: [ChipItem] = [
        ChipItem(id: "nausea",             label: "Nausea"),
        ChipItem(id: "light_sensitivity",  label: "Light sensitivity"),
        ChipItem(id: "sound_sensitivity",  label: "Sound sensitivity"),
        ChipItem(id: "aura",               label: "Visual aura"),
        ChipItem(id: "neck_pain",          label: "Neck stiffness"),
        ChipItem(id: "visual_disturbance", label: "Fatigue"),
        ChipItem(id: "vomiting",           label: "Vomiting"),
        ChipItem(id: "dizziness",          label: "Dizziness"),
    ]
}

/// Headache location options (stored as-is in headacheLocation).
/// Must match LogHeadacheModal.locationOptions so pre-population from log time works.
extension RetrospectiveViewModel {
    static let locationOptions: [String] = [
        "Forehead", "Temples", "Back of head", "One side", "Entire head"
    ]
}

/// Headache type options mapping to canonical model keys.
extension RetrospectiveViewModel {
    static let headacheTypeOptions: [(label: String, key: String)] = [
        ("Tension",  "tension"),
        ("Migraine", "migraine"),
        ("Cluster",  "cluster"),
        ("Unknown",  "unknown"),
    ]
}

/// Cycle phase options mapping to canonical model keys.
extension RetrospectiveViewModel {
    static let cyclePhaseOptions: [(label: String, key: String)] = [
        ("Menstrual",  "menstrual"),
        ("Follicular", "follicular"),
        ("Ovulation",  "ovulatory"),
        ("Luteal",     "luteal"),
    ]
}

/// Medication name suggestions for the text field suggestion list.
extension RetrospectiveViewModel {
    static let medicationSuggestions: [String] = [
        "Ibuprofen", "Paracetamol", "Sumatriptan", "Aspirin", "Naproxen",
    ]
}
