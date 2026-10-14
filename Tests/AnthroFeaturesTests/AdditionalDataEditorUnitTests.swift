import AnthroCore
import AnthroFeatures
import Foundation
import Testing

@MainActor
@Suite("additional-data: editor de definição (unitários)")
struct AdditionalDataEditorUnitTests {
    private func vars(_ e: AdditionalDataEditorModel, _ section: Int) -> [AdditionalDataVariable] {
        e.definition.sections.indices.contains(section) ? e.definition.sections[section].variables : []
    }

    private func editor() -> AdditionalDataEditorModel {
        AdditionalDataEditorModel(definition: AdditionalData(sections: [
            AdditionalDataSection(identifier: "A", variables: [textVariable("x"), textVariable("y")]),
            AdditionalDataSection(identifier: "B"),
        ]))
    }

    @Test func deletingVariableKeepsSiblingsAndClearsSelection() {
        let e = editor()
        e.selection = .variable(section: 0, variable: 0)
        e.deleteSelected()
        #expect(vars(e, 0).map(\.identifier) == ["y"])
        #expect(e.selection == nil)
        #expect(!e.canAddVariable)
        e.deleteSelected()
        #expect(e.definition.sections.count == 2)
    }

    @Test func addSectionAppendsEmptySectionAndSelectsIt() {
        let e = editor()
        e.addSection()
        #expect(e.definition.sections.last == AdditionalDataSection(identifier: ""))
        #expect(e.selection == .section(2))
    }

    @Test func addVariableOnSelectedSectionAppendsAndSelects() {
        let e = editor()
        e.selection = .section(1)
        e.addVariable()
        #expect(vars(e, 1) == [AdditionalDataVariable(identifier: "", kind: .text(nil))])
        #expect(e.selection == .variable(section: 1, variable: 0))
    }

    @Test func editsWithoutApplicableSelectionAreIgnored() {
        let e = editor()
        let before = e.definition
        e.selection = nil
        e.setIdentifier("Z")
        e.setDescription("d")
        e.selection = .section(0)
        e.setKind(.number)
        e.setMinimum(1)
        e.setMaximum(2)
        #expect(e.definition == before)
        e.selection = .variable(section: 0, variable: 0)
        e.setMinimum(1)
        #expect(e.definition == before)
        e.selection = .section(9)
        e.setIdentifier("Z")
        #expect(e.definition == before)
    }

    @Test func descriptionIsTrimmedAndKept() {
        let e = editor()
        e.selection = .variable(section: 0, variable: 1)
        e.setDescription("  horas  ")
        #expect(vars(e, 0).dropFirst(1).first?.description == "horas")
    }

    @Test func applyRejectsEmptyVariableIdentifierAndRepeatedSections() {
        let e = editor()
        e.selection = .variable(section: 0, variable: 1)
        e.setIdentifier("   ")
        #expect(throws: AdditionalDataEditorError.emptyIdentifier) { try e.apply() }
        e.setIdentifier("z")
        e.selection = .section(1)
        e.setIdentifier("A")
        #expect(throws: AdditionalDataEditorError.duplicateIdentifier(section: "A", variable: nil)) { try e.apply() }
    }

    /// `rbType_CheckedChanged` não dispara no tipo já marcado: escolher de novo o mesmo tipo não apaga os limites.
    @Test func choosingTheSameKindKeepsLimitsAndOtherKindClearsThem() {
        let e = AdditionalDataEditorModel(definition: AdditionalData(sections: [AdditionalDataSection(identifier: "A",
            variables: [numberVariable("n", value: 3, minimum: 0, maximum: 9)])]))
        e.selection = .variable(section: 0, variable: 0)
        e.setKind(.number)
        #expect(vars(e, 0).dropFirst(0).first == numberVariable("n", value: 3, minimum: 0, maximum: 9))
        e.setKind(.text)
        #expect(vars(e, 0).dropFirst(0).first == textVariable("n"))
    }
}
