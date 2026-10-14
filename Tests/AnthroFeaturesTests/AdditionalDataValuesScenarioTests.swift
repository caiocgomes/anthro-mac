import AnthroCore
import AnthroFeatures
import Foundation
import Testing

/// Cenários do formulário de valores e dos rótulos em pt-BR (change add-additional-data).
@MainActor
@Suite("additional-data: formulário de valores")
struct AdditionalDataValuesScenarioTests {
    // Scenario: Texto e data preenchidos
    @Test func valuesFormStoresTrimmedTextAndDate() throws {
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola", variables: [
            textVariable("Série"), AdditionalDataVariable(identifier: "Início", kind: .date(nil)),
        ])])
        let m = AdditionalDataValuesModel(data: data)
        m.setText(" 3º ano ", section: 0, variable: 0)
        m.setDate(day("2021-04-01"), section: 0, variable: 1)
        let result = try m.result()
        #expect(result.variable(section: "Escola", variable: "Série")?.kind == .text("3º ano"))
        #expect(result.variable(section: "Escola", variable: "Início")?.kind == .date(day("2021-04-01")))
    }

    // Scenario: Texto apagado
    @Test func clearedTextBecomesNilAndOpenCloseElement() throws {
        let m = AdditionalDataValuesModel(data: AdditionalData(sections: [
            AdditionalDataSection(identifier: "S", variables: [textVariable("t", "abc")]),
        ]))
        m.setText("", section: 0, variable: 0)
        let result = try m.result()
        #expect(result.variable(section: "S", variable: "t")?.kind == .text(nil))
        #expect(AdditionalDataXML.encode(result).contains(#"<Txt ID="t" Descr=""></Txt>"#))
    }

    // Scenario: Número dentro dos limites
    @Test func numberWithCommaIsParsedAndShownWithTwoDecimals() throws {
        let m = AdditionalDataValuesModel(data: try AdditionalDataXML.decode(iaTemplateXML))
        m.setNumber("7,5", section: 1, variable: 0)
        #expect(m.outcome(section: 1, variable: 0) == .value(num("7.5")))
        #expect(m.displayText(section: 1, variable: 0) == "7,50")
        #expect(m.canSave)
        #expect(try m.result().variable(section: "Physical activity", variable: "Sport")?.kind
            == .number(value: num("7.5"), minimum: 0, maximum: 140))
    }

    // Scenario: Número fora dos limites e texto inválido
    @Test func outOfRangeAndInvalidNumbersWarnAndBlockSave() throws {
        let m = AdditionalDataValuesModel(data: try AdditionalDataXML.decode(iaTemplateXML))
        m.setNumber("141", section: 1, variable: 0)
        m.setNumber("dez", section: 1, variable: 1)
        #expect(m.outcome(section: 1, variable: 0) == .outOfRange(0...140))
        #expect(m.outcome(section: 1, variable: 1) == .invalid)
        #expect(m.warnings.count == 2)
        #expect(!m.canSave)
        #expect(throws: AdditionalDataValueError(issues: [
            .outOfRange(section: "Physical activity", variable: "Sport"),
            .invalid(section: "Physical activity", variable: "TV/computer"),
        ])) { try m.result() }
    }

    // Scenario: Rótulos traduzidos
    @Test func defaultTemplateLabelsAreTranslated() throws {
        let m = AdditionalDataValuesModel(data: try AdditionalDataXML.decode(iaTemplateXML))
        var titles: [String] = []
        for field in m.fields where titles.last != field.sectionTitle { titles.append(field.sectionTitle) }
        #expect(titles == ["Maturação", "Atividade física", "Alimentação", "Saúde"])
        #expect(m.fields.first { $0.sectionIndex == 2 && $0.variableIndex == 0 }?.label
            == "Porções de frutas e hortaliças por dia")
    }

    // Scenario: Identificador da usuária
    @Test func userIdentifierIsShownAsTypedAndKeptInXML() throws {
        let e = AdditionalDataEditorModel(definition: AdditionalData())
        e.addSection()
        e.setIdentifier("Escola")
        e.addVariable()
        e.setIdentifier("Série")
        let definition = try e.apply()
        #expect(AdditionalDataLabels.display("Escola") == "Escola")
        #expect(AdditionalDataValuesModel(data: definition).fields.map(\.sectionTitle) == ["Escola"])
        #expect(AdditionalDataXML.encode(definition).contains(#"<Cat ID="Escola" Descr="">"#))
    }
}
