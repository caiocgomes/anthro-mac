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

/// Formulário de valores das telas de visita e de registro (`CreateAddDataControls` e `SaveAddDataFromControls`,
/// design D8): variáveis em ordem de seção, texto aparado, número avaliado pelo helper compartilhado com o intervalo da
/// variável e 2 casas, data opcional. Valor carregado e não tocado volta como estava (D11).
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

    /// Texto corrente de cada variável de texto e de número, pela chave do campo.
    private var texts: [String: String] = [:]
    private var dates: [String: Date?] = [:]

    @ObservationIgnored private let initial: AdditionalData
    /// Texto com que cada campo foi montado; texto igual a ele devolve o valor gravado.
    @ObservationIgnored private var loadedTexts: [String: String] = [:]

    /// `decimal.MinValue` e `decimal.MaxValue`, os limites do `NumericUpDownX` sem mínimo ou máximo.
    static let decimalMax = Decimal(string: "79228162514264337593543950335")!

    public init(data: AdditionalData) {
        initial = data
        for (sectionIndex, section) in data.sections.enumerated() {
            for (variableIndex, variable) in section.variables.enumerated() {
                let key = Self.key(sectionIndex, variableIndex)
                let kind: AdditionalDataEditorModel.KindChoice
                switch variable.kind {
                case .text(let value):
                    kind = .text
                    texts[key] = value ?? ""
                case .number(let value, _, _):
                    kind = .number
                    texts[key] = value.map { ClinicalFormat.string($0, places: 2) } ?? ""
                case .date(let value):
                    kind = .date
                    dates[key] = value
                }
                fields.append(Field(id: key, sectionTitle: AdditionalDataLabels.display(section.identifier),
                                    label: AdditionalDataLabels.display(variable.identifier),
                                    sectionIndex: sectionIndex, variableIndex: variableIndex, kind: kind))
            }
        }
        loadedTexts = texts
    }

    // MARK: Entrada

    public func setText(_ text: String, section: Int, variable: Int) {
        guard case .text = variableAt(section, variable)?.kind else { return }
        texts[Self.key(section, variable)] = text
    }

    public func setNumber(_ text: String, section: Int, variable: Int) {
        guard case .number = variableAt(section, variable)?.kind else { return }
        texts[Self.key(section, variable)] = text
    }

    /// `NullableDateTimePicker`: data opcional, guardada como o meio-dia do dia escolhido.
    public func setDate(_ date: Date?, section: Int, variable: Int) {
        guard case .date = variableAt(section, variable)?.kind else { return }
        dates[Self.key(section, variable)] = date.map(IndividualAssessment.normalized)
    }

    public func date(section: Int, variable: Int) -> Date? {
        dates[Self.key(section, variable)] ?? nil
    }

    // MARK: Avaliação

    /// Avaliação do número com o intervalo da variável; número carregado e não tocado vale o que foi gravado.
    public func outcome(section: Int, variable: Int) -> MeasurementInput.Outcome {
        guard let found = variableAt(section, variable),
              case .number(let stored, let minimum, let maximum) = found.kind else { return .empty }
        let key = Self.key(section, variable)
        let text = texts[key] ?? ""
        if text == loadedTexts[key] { return stored.map { .value($0) } ?? .empty }
        return MeasurementInput.evaluate(text, range: Self.range(minimum, maximum), places: 2)
    }

    /// Texto da variável de texto; número válido com 2 casas, inválido ou fora do intervalo como foi digitado.
    public func displayText(section: Int, variable: Int) -> String {
        guard let found = variableAt(section, variable) else { return "" }
        let key = Self.key(section, variable)
        switch found.kind {
        case .text:
            return texts[key] ?? ""
        case .number:
            let text = texts[key] ?? ""
            if text == loadedTexts[key] { return text }
            if case .value(let value) = outcome(section: section, variable: variable) {
                return ClinicalFormat.string(value, places: 2)
            }
            return text
        case .date:
            return ""
        }
    }

    /// Aviso por campo (`Field.id`): valor inválido, fora do intervalo ou abaixo ou acima do único limite.
    public var warnings: [String: String] {
        var warnings: [String: String] = [:]
        for field in fields where field.kind == .number {
            guard let found = variableAt(field.sectionIndex, field.variableIndex),
                  case .number(_, let minimum, let maximum) = found.kind else { continue }
            switch outcome(section: field.sectionIndex, variable: field.variableIndex) {
            case .invalid:
                warnings[field.id] = L10n.Calculator.invalidValue
            case .outOfRange(let range):
                switch (minimum, maximum) {
                case (let low?, nil): warnings[field.id] = "\(L10n.AddData.minimumPrefix) \(Self.plain(low))"
                case (nil, let high?): warnings[field.id] = "\(L10n.AddData.maximumPrefix) \(Self.plain(high))"
                default: warnings[field.id] = MeasurementInput.Outcome.outOfRange(range).issueMessage
                }
            case .empty, .value:
                break
            }
        }
        return warnings
    }

    /// Número ilegível ou fora do intervalo bloqueia salvar a visita ou o registro; vazio é permitido.
    public var canSave: Bool {
        issues.isEmpty
    }

    /// Dados com os valores do formulário; lança com os campos inválidos.
    public func result() throws -> AdditionalData {
        let issues = issues
        guard issues.isEmpty else { throw AdditionalDataValueError(issues: issues) }
        var data = initial
        for field in fields {
            let (s, v) = (field.sectionIndex, field.variableIndex)
            let key = Self.key(s, v)
            switch data.sections[s].variables[v].kind {
            case .text(let stored):
                let text = texts[key] ?? ""
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                data.sections[s].variables[v].kind = .text(text == loadedTexts[key] ? stored : (trimmed.isEmpty ? nil : trimmed))
            case .number(_, let minimum, let maximum):
                let value = outcome(section: s, variable: v).value
                data.sections[s].variables[v].kind = .number(value: value, minimum: minimum, maximum: maximum)
            case .date:
                data.sections[s].variables[v].kind = .date(dates[key] ?? nil)
            }
        }
        return data
    }

    /// Sem diferença entre o resultado e os dados de partida, o XML original é gravado intacto (D11).
    var isUnchanged: Bool {
        (try? result()) == initial
    }

    // MARK: Privado

    private var issues: Set<AdditionalDataValueIssue> {
        var issues: Set<AdditionalDataValueIssue> = []
        for field in fields where field.kind == .number {
            let section = initial.sections[field.sectionIndex]
            let variable = section.variables[field.variableIndex]
            switch outcome(section: field.sectionIndex, variable: field.variableIndex) {
            case .invalid: issues.insert(.invalid(section: section.identifier, variable: variable.identifier))
            case .outOfRange: issues.insert(.outOfRange(section: section.identifier, variable: variable.identifier))
            case .empty, .value: break
            }
        }
        return issues
    }

    private func variableAt(_ section: Int, _ variable: Int) -> AdditionalDataVariable? {
        guard initial.sections.indices.contains(section),
              initial.sections[section].variables.indices.contains(variable) else { return nil }
        return initial.sections[section].variables[variable]
    }

    private static func key(_ section: Int, _ variable: Int) -> String {
        "\(section)-\(variable)"
    }

    /// `Min...Max` da variável, com o limite ausente como `decimal.MinValue` ou `decimal.MaxValue`; limites invertidos
    /// (arquivo importado) são lidos na ordem crescente.
    private static func range(_ minimum: Decimal?, _ maximum: Decimal?) -> ClosedRange<Decimal> {
        let low = minimum ?? -decimalMax
        let high = maximum ?? decimalMax
        return Swift.min(low, high)...Swift.max(low, high)
    }

    /// Número com vírgula e as casas que tiver.
    private static func plain(_ value: Decimal) -> String {
        "\(value)".replacingOccurrences(of: ".", with: ",")
    }
}
