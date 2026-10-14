import AnthroCore
import AnthroFeatures
import Foundation
import Testing

@MainActor
@Suite("additional-data: formulário de valores (unitários)")
struct AdditionalDataValuesUnitTests {
    private func model(_ variables: [AdditionalDataVariable], section: String = "S") -> AdditionalDataValuesModel {
        AdditionalDataValuesModel(data: AdditionalData(sections: [AdditionalDataSection(identifier: section,
                                                                                         variables: variables)]))
    }

    @Test func untouchedStoredNumberOutsideLimitsKeepsValueAndDoesNotBlock() throws {
        let m = model([numberVariable("n", value: num("150.125"), minimum: 0, maximum: 140)])
        #expect(m.canSave)
        #expect(m.warnings.isEmpty)
        #expect(m.outcome(section: 0, variable: 0) == .value(num("150.125")))
        #expect(try m.result() == AdditionalData(sections: [AdditionalDataSection(identifier: "S", variables: [
            numberVariable("n", value: num("150.125"), minimum: 0, maximum: 140)])]))
    }

    @Test func retypingTheStoredNumberIsEvaluatedAgain() {
        let m = model([numberVariable("n", value: num("150"), minimum: 0, maximum: 140)])
        m.setNumber("150", section: 0, variable: 0)
        #expect(!m.canSave)
        #expect(m.displayText(section: 0, variable: 0) == "150")
    }

    @Test func numberIsTruncatedToTwoPlacesAndInvalidTextIsShownAsTyped() throws {
        let m = model([numberVariable("n"), numberVariable("m")])
        m.setNumber("2,999", section: 0, variable: 0)
        m.setNumber("dois", section: 0, variable: 1)
        #expect(m.outcome(section: 0, variable: 0) == .value(num("2.99")))
        #expect(m.displayText(section: 0, variable: 0) == "2,99")
        #expect(m.displayText(section: 0, variable: 1) == "dois")
        #expect(m.warnings == ["0-1": "Valor inválido"])
    }

    @Test func oneSidedLimitWarningNamesOnlyThatLimit() {
        let m = model([numberVariable("n", minimum: 0), numberVariable("m", maximum: 10)])
        m.setNumber("-1", section: 0, variable: 0)
        m.setNumber("11", section: 0, variable: 1)
        #expect(m.warnings == ["0-0": "Valor mínimo: 0", "0-1": "Valor máximo: 10"])
    }

    @Test func fieldsFollowDefinitionOrderSkipEmptySectionsAndCarryKind() {
        let m = AdditionalDataValuesModel(data: AdditionalData(sections: [
            AdditionalDataSection(identifier: "Vazia"),
            AdditionalDataSection(identifier: "Physical activity", variables: [
                numberVariable("Sport"), textVariable("Nota"), AdditionalDataVariable(identifier: "Dia", kind: .date(nil)),
            ]),
        ]))
        #expect(m.fields.map(\.id) == ["1-0", "1-1", "1-2"])
        #expect(m.fields.map(\.label) == ["Esporte", "Nota", "Dia"])
        #expect(m.fields.map(\.sectionTitle) == ["Atividade física", "Atividade física", "Atividade física"])
        #expect(m.fields.map(\.kind) == [.number, .text, .date])
    }

    @Test func dateIsNormalizedToNoonAndCanBeCleared() throws {
        let m = model([AdditionalDataVariable(identifier: "d", kind: .date(day("2020-01-01")))])
        #expect(m.date(section: 0, variable: 0) == day("2020-01-01"))
        let lateEvening = Calendar.current.date(byAdding: .hour, value: 11, to: day("2021-04-01"))!
        m.setDate(lateEvening, section: 0, variable: 0)
        #expect(m.date(section: 0, variable: 0) == day("2021-04-01"))
        m.setDate(nil, section: 0, variable: 0)
        #expect(try m.result().sections.first?.variables.first?.kind == .date(nil))
    }

    @Test func settersOfTheWrongKindAreIgnored() throws {
        let m = model([textVariable("t", "abc"), numberVariable("n", value: 1)])
        m.setNumber("5", section: 0, variable: 0)
        m.setText("x", section: 0, variable: 1)
        m.setDate(day("2021-04-01"), section: 0, variable: 0)
        #expect(try m.result().sections.first?.variables.map(\.kind) == [.text("abc"), .number(value: 1, minimum: nil, maximum: nil)])
    }
}
