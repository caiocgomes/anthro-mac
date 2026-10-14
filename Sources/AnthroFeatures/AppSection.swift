/// Os três módulos do WHO AnthroPlus, na ordem da sidebar.
public enum AppSection: String, CaseIterable, Sendable, Codable {
    case calculator
    case individualAssessment
    case nutritionalSurvey

    public var title: String {
        ""
    }

    public var systemImage: String {
        ""
    }

    public var shortcutNumber: Int {
        0
    }
}
