import AnthroCore

/// Envelope de troca do inquérito: o `Survey` e os seus `SurveyRecord` da change 5, sem campos próprios (design D17).
public struct ExchangeSurvey: Equatable, Sendable {
    public var survey: Survey
    public var records: [SurveyRecord]

    public init(survey: Survey, records: [SurveyRecord]) {
        self.survey = survey
        self.records = records
    }
}
