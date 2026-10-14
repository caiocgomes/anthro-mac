import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Editor de visita (`IAVisitDialog`).
@MainActor
@Observable
public final class VisitEditorModel {
    public var date: Date = Date(timeIntervalSince1970: 0)
    public var weightText: String = ""
    public var lengthOrHeightText: String = ""
    public var measuredRecumbent: Bool = false
    public var hasOedema: Bool = false
    public var notes: String = ""

    public init(dateOfBirth: Date, sex: Sex?, existingDates: Set<Date>, editing: VisitRecord?, engine: AnthroEngine,
                today: Date) {}

    public var isDateEditable: Bool { false }
    public var weightOutcome: MeasurementInput.Outcome { .empty }
    public var lengthOrHeightOutcome: MeasurementInput.Outcome { .empty }
    public var weightWarning: String? { nil }
    public var lengthOrHeightWarning: String? { nil }
    public var canSave: Bool { false }
    public var weight: Decimal? { nil }
    public var lengthOrHeight: Decimal? { nil }
    public var isMeasureChoiceEnabled: Bool { false }
    public var bmiText: String { "" }

    public func makeVisit() throws -> VisitRecord {
        VisitRecord(date: Date(timeIntervalSince1970: 0))
    }
}
