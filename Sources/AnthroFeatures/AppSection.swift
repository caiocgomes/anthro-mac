/// Os três módulos do WHO AnthroPlus, na ordem da sidebar.
public enum AppSection: String, CaseIterable, Sendable, Codable {
    case calculator
    case individualAssessment
    case nutritionalSurvey

    public var title: String {
        switch self {
        case .calculator: L10n.Section.calculator
        case .individualAssessment: L10n.Section.individualAssessment
        case .nutritionalSurvey: L10n.Section.nutritionalSurvey
        }
    }

    public var systemImage: String {
        switch self {
        case .calculator: "plusminus.circle"
        case .individualAssessment: "person.text.rectangle"
        case .nutritionalSurvey: "chart.bar.doc.horizontal"
        }
    }

    /// Número do atalho ⌘1 a ⌘3, na ordem de `allCases`.
    public var shortcutNumber: Int {
        Self.allCases.firstIndex(of: self)! + 1
    }
}
