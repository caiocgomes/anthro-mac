import AnthroCore
import Foundation

public enum SurveyStoreError: Error, Equatable {
    case nameRequired
    case notFound(Int64)
}

/// Inquéritos e registros no banco (`Surveys` e `Records` do DAL original, design D2 e D3).
public struct SurveyRepository: Sendable {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    public func list(archived: Bool) throws -> [Survey] {
        []
    }

    public func survey(id: Int64) throws -> Survey {
        Survey()
    }

    public func records(surveyID: Int64) throws -> [SurveyRecord] {
        []
    }

    public func save(_ survey: Survey, records: [SurveyRecord]) throws -> (survey: Survey, records: [SurveyRecord]) {
        (survey, records)
    }

    public func setArchived(_ ids: [Int64], archived: Bool) throws {}

    public func delete(_ ids: [Int64]) throws {}
}
