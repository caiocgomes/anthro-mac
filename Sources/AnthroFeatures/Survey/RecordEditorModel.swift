import AnthroCore
import Foundation
import Observation

/// Campos numéricos do editor de registro com intervalo e casas do controle de `NSRecordDialog` (design D11).
public enum RecordNumericField: Hashable, Sendable, CaseIterable {
    case weight, lengthOrHeight, ageInMonths, cluster, team, displayID, household, weightingFactor

    public var range: ClosedRange<Decimal> { 0...0 }

    public var places: Int { 0 }
}

public enum AutoIDField: Hashable, Sendable, CaseIterable {
    case cluster, team, record, household
}

public enum RecordFieldIssue: Hashable, Sendable {
    case invalid(RecordNumericField)
    case outOfRange(RecordNumericField)
    case required(RecordNumericField)
}

public struct RecordValidationError: Error, Equatable {
    public let issues: Set<RecordFieldIssue>
}

/// Editor de registro do inquérito (`NSRecordDialog`).
@MainActor
@Observable
public final class RecordEditorModel {
    public private(set) var visitDate: Date? = nil
    public private(set) var dateOfBirth: Date = Date(timeIntervalSince1970: 0)
    public var dateOfBirthUnknown: Bool = false
    public private(set) var dateOfBirthIsApprox: Bool = false
    public var firstName: String = ""
    public var lastName: String = ""
    public var notes: String = ""
    public var sex: Sex = .girl
    public private(set) var measuredRecumbent: Bool = false
    public var hasOedema: Bool = false

    public init(record: SurveyRecord?, survey: Survey, existingRecords: [SurveyRecord], engine: AnthroEngine, today: Date,
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {}

    public func text(_ field: RecordNumericField) -> String { "" }

    public func setText(_ text: String, for field: RecordNumericField) {}

    public func outcome(_ field: RecordNumericField) -> MeasurementInput.Outcome { .empty }

    public func value(_ field: RecordNumericField) -> Decimal? { nil }

    public var warnings: [RecordNumericField: String] { [:] }

    public var canSave: Bool { false }

    public var ageText: String { "" }

    public var isMeasureChoiceEnabled: Bool { false }

    public var isAgeEntryEnabled: Bool { false }

    public var bmiText: String { "" }

    public func isAutoAssigned(_ field: AutoIDField) -> Bool { false }

    public func setVisitDate(_ date: Date?) {}

    public func setDateOfBirth(_ date: Date) {}

    public func setDateOfBirthIsApprox(_ approx: Bool) {}

    public func setMeasuredRecumbent(_ recumbent: Bool) {}

    public func makeRecord() throws -> SurveyRecord { SurveyRecord() }
}
