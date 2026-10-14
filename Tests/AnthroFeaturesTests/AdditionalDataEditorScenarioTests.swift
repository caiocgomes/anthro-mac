import AnthroCore
import AnthroFeatures
import Foundation
import Testing

/// Cenários do editor de definição de dados adicionais (`AdditionalDataDialog`, change add-additional-data).
@MainActor
@Suite("additional-data: editor de definição")
struct AdditionalDataEditorScenarioTests {
    private func editor(_ sections: [AdditionalDataSection]) -> AdditionalDataEditorModel {
        AdditionalDataEditorModel(definition: AdditionalData(sections: sections))
    }

    // Scenario: Variável incluída a partir de variável selecionada
    @Test func addVariableFromSelectedVariableAppendsToItsSection() throws {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [textVariable("x")])])
        e.selection = .variable(section: 0, variable: 0)
        e.addVariable()
        let section = try #require(e.definition.section("A"))
        #expect(section.variables.count == 2)
        #expect(section.variables.last == AdditionalDataVariable(identifier: "", kind: .text(nil)))
        #expect(e.selection == .variable(section: 0, variable: 1))
        #expect(e.definition.sections.count == 1)
    }

    // Scenario: Incluir variável sem seleção
    @Test func addVariableRequiresSelection() {
        let original = AdditionalData(sections: [AdditionalDataSection(identifier: "A")])
        let e = AdditionalDataEditorModel(definition: original)
        e.selection = nil
        #expect(!e.canAddVariable)
        e.addVariable()
        #expect(e.definition == original)
        e.selection = .section(0)
        #expect(e.canAddVariable)
    }

    // Scenario: Identificador aparado
    @Test func identifierIsTrimmedAndEmptyDescriptionIsNil() throws {
        let e = editor([])
        e.addSection()
        e.setIdentifier("  Escola  ")
        e.setDescription("  ")
        let applied = try e.apply()
        #expect(applied.sections == [AdditionalDataSection(identifier: "Escola", description: nil)])
    }

    // Scenario: Seção sem identificador
    @Test func emptySectionIdentifierThrowsOnApply() {
        let e = editor([])
        e.addSection()
        #expect(throws: AdditionalDataEditorError.emptyIdentifier) { try e.apply() }
    }

    // Scenario: Variáveis repetidas na mesma seção
    @Test func duplicateVariableInSectionThrowsOnApply() {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [textVariable("x"), textVariable("x")])])
        #expect(throws: AdditionalDataEditorError.duplicateIdentifier(section: "A", variable: "x")) { try e.apply() }
    }

    // Scenario: Mesmo identificador em seções diferentes
    @Test func sameVariableInDifferentSectionsIsAccepted() throws {
        let sections = [AdditionalDataSection(identifier: "A", variables: [textVariable("x")]),
                        AdditionalDataSection(identifier: "B", variables: [textVariable("x")])]
        let applied = try editor(sections).apply()
        #expect(applied.sections.count == 2)
        #expect(applied == AdditionalData(sections: sections))
    }

    // Scenario: Número vira data
    @Test func changingKindKeepsPositionAndIdentifier() throws {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [
            textVariable("t"),
            AdditionalDataVariable(identifier: "n", description: "nota", kind: .number(value: 3, minimum: 0, maximum: 10)),
        ])])
        e.selection = .variable(section: 0, variable: 1)
        e.setKind(.date)
        let variables = try #require(e.definition.section("A")).variables
        #expect(variables.count == 2)
        #expect(variables.last == AdditionalDataVariable(identifier: "n", description: "nota", kind: .date(nil)))
    }

    // Scenario: Texto vira número sem limites
    @Test func textToNumberStartsWithoutLimits() throws {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [
            numberVariable("m", minimum: 1, maximum: 5), textVariable("t", "abc"),
        ])])
        e.selection = .variable(section: 0, variable: 1)
        e.setKind(.number)
        let variable = try #require(e.definition.section("A")?.variables.last)
        #expect(variable == numberVariable("t"))
    }

    // Scenario: Mínimo acima do máximo
    @Test func minimumAboveMaximumIsClamped() throws {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [numberVariable("n", maximum: 10)])])
        e.selection = .variable(section: 0, variable: 0)
        e.setMinimum(12)
        let variable = try #require(e.definition.section("A")?.variables.first)
        #expect(variable == numberVariable("n", minimum: 10, maximum: 10))
    }

    // Scenario: Máximo abaixo do mínimo e limite vazio
    @Test func maximumBelowMinimumIsClampedAndEmptyAllowed() throws {
        let e = editor([AdditionalDataSection(identifier: "A", variables: [numberVariable("n", minimum: 5)])])
        e.selection = .variable(section: 0, variable: 0)
        e.setMaximum(2)
        e.setMinimum(nil)
        let variable = try #require(e.definition.section("A")?.variables.first)
        #expect(variable == numberVariable("n", minimum: nil, maximum: 5))
    }

    // Scenario: Excluir seção
    @Test func deletingSectionRemovesItsVariables() throws {
        let e = AdditionalDataEditorModel(definition: try AdditionalDataXML.decode(iaTemplateXML))
        let food = try #require(e.definition.sections.firstIndex { $0.identifier == "Food" })
        e.selection = .section(food)
        e.deleteSelected()
        #expect(e.definition.sections.map(\.identifier) == ["Maturation", "Physical activity", "Health"])
    }
}
