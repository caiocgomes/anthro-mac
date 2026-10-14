import AnthroCore
import Foundation
import Observation

public enum AdditionalDataEditorError: Error, Equatable {
    case emptyIdentifier
    case duplicateIdentifier(section: String, variable: String?)
}

/// Editor de definição de dados adicionais (`AdditionalDataDialog`) sobre uma cópia (design D7).
@MainActor
@Observable
public final class AdditionalDataEditorModel {
    public enum Selection: Equatable, Sendable {
        case section(Int)
        case variable(section: Int, variable: Int)
    }

    public enum KindChoice: Sendable {
        case text, number, date
    }

    public private(set) var definition: AdditionalData
    public var selection: Selection?

    public init(definition: AdditionalData) {
        self.definition = AdditionalData()
    }

    public var canAddVariable: Bool { false }

    public func addSection() {}

    public func addVariable() {}

    public func deleteSelected() {}

    public func setIdentifier(_ text: String) {}

    public func setDescription(_ text: String) {}

    public func setKind(_ kind: KindChoice) {}

    public func setMinimum(_ value: Decimal?) {}

    public func setMaximum(_ value: Decimal?) {}

    public func apply() throws -> AdditionalData {
        AdditionalData()
    }
}
