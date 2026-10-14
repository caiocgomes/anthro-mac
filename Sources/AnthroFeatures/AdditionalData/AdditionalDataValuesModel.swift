import AnthroCore
import Foundation
import Observation

public enum AdditionalDataValueIssue: Hashable, Sendable {
    case invalid(section: String, variable: String)
    case outOfRange(section: String, variable: String)
}

public struct AdditionalDataValueError: Error, Equatable {
    public let issues: Set<AdditionalDataValueIssue>

    public init(issues: Set<AdditionalDataValueIssue>) {
        self.issues = issues
    }
}

/// Formulário de valores das telas de visita e de registro (`CreateAddDataControls`, design D8).
@MainActor
@Observable
public final class AdditionalDataValuesModel {
    public struct Field: Sendable, Equatable, Identifiable {
        public let id: String
        public let sectionTitle: String
        public let label: String
        public let sectionIndex: Int
        public let variableIndex: Int
        public let kind: AdditionalDataEditorModel.KindChoice
    }

    public private(set) var fields: [Field] = []

    public init(data: AdditionalData) {}

    public func setText(_ text: String, section: Int, variable: Int) {}

    public func setNumber(_ text: String, section: Int, variable: Int) {}

    public func setDate(_ date: Date?, section: Int, variable: Int) {}

    public func date(section: Int, variable: Int) -> Date? {
        nil
    }

    public func outcome(section: Int, variable: Int) -> MeasurementInput.Outcome {
        .empty
    }

    public func displayText(section: Int, variable: Int) -> String {
        ""
    }

    public var warnings: [String: String] { [:] }

    public var canSave: Bool { true }

    public func result() throws -> AdditionalData {
        AdditionalData()
    }
}
