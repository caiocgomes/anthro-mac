import AnthroCore
import Foundation
import Observation

public enum AdditionalDataEditorError: Error, Equatable {
    case emptyIdentifier
    case duplicateIdentifier(section: String, variable: String?)
}

/// Editor de definição de dados adicionais (`AdditionalDataDialog`) sobre uma cópia (design D7): nada sai do editor
/// antes de `apply()`, e cancelar é descartá-lo.
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
        self.definition = definition
    }

    /// `RefreshForSelectedItem`: incluir variável e excluir exigem um item selecionado.
    public var canAddVariable: Bool {
        selectedSectionIndex != nil
    }

    /// `tsbNewSection_Click`: seção com identificador vazio ao fim, selecionada.
    public func addSection() {
        definition.sections.append(AdditionalDataSection(identifier: ""))
        selection = .section(definition.sections.count - 1)
    }

    /// `tsbNewVariable_Click`: texto vazio ao fim da seção selecionada ou da seção da variável selecionada.
    public func addVariable() {
        guard let section = selectedSectionIndex else { return }
        definition.sections[section].variables.append(AdditionalDataVariable(identifier: "", kind: .text(nil)))
        selection = .variable(section: section, variable: definition.sections[section].variables.count - 1)
    }

    /// `tsbDelete_Click` seguido de `RefreshTree`: a árvore é refeita sem item selecionado.
    public func deleteSelected() {
        switch selection {
        case .section(let section) where definition.sections.indices.contains(section):
            definition.sections.remove(at: section)
        case .variable(let section, let variable) where isValid(section, variable):
            definition.sections[section].variables.remove(at: variable)
        default:
            return
        }
        selection = nil
    }

    /// `txtID_TextChanged`: identificador sem espaços nas pontas.
    public func setIdentifier(_ text: String) {
        let identifier = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch selection {
        case .section(let section) where definition.sections.indices.contains(section):
            definition.sections[section].identifier = identifier
        case .variable(let section, let variable) where isValid(section, variable):
            definition.sections[section].variables[variable].identifier = identifier
        default:
            break
        }
    }

    /// `txtDescription_TextChanged` com `TextToNullableString`.
    public func setDescription(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = trimmed.isEmpty ? nil : trimmed
        switch selection {
        case .section(let section) where definition.sections.indices.contains(section):
            definition.sections[section].description = description
        case .variable(let section, let variable) where isValid(section, variable):
            definition.sections[section].variables[variable].description = description
        default:
            break
        }
    }

    /// `rbType_CheckedChanged`: nova variável do tipo escolhido na mesma posição, com identificador e descrição, sem
    /// valor nem limites; o mesmo tipo de novo não muda nada, porque o rádio já marcado não dispara o evento.
    public func setKind(_ kind: KindChoice) {
        guard case .variable(let section, let variable) = selection, isValid(section, variable) else { return }
        let current: KindChoice = switch definition.sections[section].variables[variable].kind {
        case .text: .text
        case .number: .number
        case .date: .date
        }
        guard kind != current else { return }
        let kindValue: AdditionalDataVariable.Kind = switch kind {
        case .text: .text(nil)
        case .number: .number(value: nil, minimum: nil, maximum: nil)
        case .date: .date(nil)
        }
        definition.sections[section].variables[variable].kind = kindValue
    }

    /// `nudMinValue_ValueChanged`: mínimo acima do máximo desce ao máximo; vazio é aceito.
    public func setMinimum(_ value: Decimal?) {
        updateLimits { minimum, maximum in
            minimum = value
            if let low = minimum, let high = maximum, low > high { minimum = high }
        }
    }

    /// `nudMaxValue_ValueChanged`: máximo abaixo do mínimo sobe ao mínimo; vazio é aceito.
    public func setMaximum(_ value: Decimal?) {
        updateLimits { minimum, maximum in
            maximum = value
            if let low = minimum, let high = maximum, low > high { maximum = low }
        }
    }

    /// Identificador obrigatório em todos os itens (`txtID_Validating`) e, como desvio, sem seções repetidas nem
    /// variáveis repetidas na mesma seção, que `FindSection` e `FindVariable` deixariam inacessíveis.
    public func apply() throws -> AdditionalData {
        var sectionIDs: Set<String> = []
        for section in definition.sections {
            guard !section.identifier.isEmpty else { throw AdditionalDataEditorError.emptyIdentifier }
            guard sectionIDs.insert(section.identifier).inserted else {
                throw AdditionalDataEditorError.duplicateIdentifier(section: section.identifier, variable: nil)
            }
            var variableIDs: Set<String> = []
            for variable in section.variables {
                guard !variable.identifier.isEmpty else { throw AdditionalDataEditorError.emptyIdentifier }
                guard variableIDs.insert(variable.identifier).inserted else {
                    throw AdditionalDataEditorError.duplicateIdentifier(section: section.identifier,
                                                                        variable: variable.identifier)
                }
            }
        }
        return definition
    }

    // MARK: Privado

    private var selectedSectionIndex: Int? {
        switch selection {
        case .section(let section) where definition.sections.indices.contains(section): section
        case .variable(let section, let variable) where isValid(section, variable): section
        default: nil
        }
    }

    private func isValid(_ section: Int, _ variable: Int) -> Bool {
        definition.sections.indices.contains(section) && definition.sections[section].variables.indices.contains(variable)
    }

    private func updateLimits(_ change: (inout Decimal?, inout Decimal?) -> Void) {
        guard case .variable(let section, let variable) = selection, isValid(section, variable),
              case .number(let value, var minimum, var maximum) = definition.sections[section].variables[variable].kind
        else { return }
        change(&minimum, &maximum)
        definition.sections[section].variables[variable].kind = .number(value: value, minimum: minimum, maximum: maximum)
    }
}
