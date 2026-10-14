import AnthroCore
import Foundation

/// Linha da tabela de registros: resultado e flags calculados uma vez (design D5).
public struct SurveyRecordRow: Sendable, Equatable {
    public let record: SurveyRecord
    public let result: AnthropometricResult

    public init(record: SurveyRecord, engine: AnthroEngine, options: SurveyOptions) {
        self.record = record
        result = engine.result(ageInDays: nil, ageInMonths: nil, sex: nil, weight: nil, lengthOrHeight: nil,
                               measuredRecumbent: false, hasOedema: false)
    }

    public func text(_ column: SurveyTableColumn) -> String {
        ""
    }

    public func isDerived(_ column: SurveyTableColumn) -> Bool {
        false
    }

    public func isHighlighted(_ column: SurveyTableColumn) -> Bool {
        false
    }

    public var flag: PlausibilityFlag {
        .none
    }
}
