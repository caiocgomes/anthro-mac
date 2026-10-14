import AnthroStore
import Foundation
import Observation

/// Editor de mãe ou pai (`IAParentDialog`).
@MainActor
@Observable
public final class ParentEditorModel {
    public var firstName: String = ""
    public var lastName: String = ""
    public var notes: String = ""
    public var heightText: String = ""
    public var weightText: String = ""
    public var dateOfBirth: Date = Date(timeIntervalSince1970: 0)
    public var dateOfBirthIsApprox: Bool = false
    public var dateOfBirthUnknown: Bool = false

    public init(kind: ParentKind, database: AnthroDatabase, editing: ParentRecord?, today: @escaping () -> Date = { Date() },
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {}

    public var heightOutcome: MeasurementInput.Outcome { .empty }
    public var weightOutcome: MeasurementInput.Outcome { .empty }
    public var heightWarning: String? { nil }
    public var weightWarning: String? { nil }
    public var canSave: Bool { false }
    public var bmiText: String { "" }

    @discardableResult public func save() throws -> ParentRecord {
        ParentRecord(kind: .mother)
    }
}
