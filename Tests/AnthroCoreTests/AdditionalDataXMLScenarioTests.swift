import AnthroCore
import Foundation
import Testing

/// XML do modelo padrão do original (`IAAdditionalDataTemplate`), lido da fixture literal.
func iaTemplateFixture() throws -> String {
    let url = try #require(Bundle.module.url(forResource: "ia-additional-data-template", withExtension: "xml",
                                             subdirectory: "Fixtures"))
    return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Cenários de leitura e escrita do XML de dados adicionais (change add-additional-data).
@Suite("additional-data: XML")
struct AdditionalDataXMLScenarioTests {
    // Scenario: Modelo padrão do original
    @Test func decodesOriginalIndividualTemplate() throws {
        let data = try AdditionalDataXML.decode(try iaTemplateFixture())
        #expect(data.sections.count == 4)
        let activity = try #require(data.sections.count > 1 ? data.sections[1] : nil)
        #expect(activity.identifier == "Physical activity")
        #expect(activity.description == "hours per week")
        #expect(activity.variables.map(\.kind) == [.number(value: nil, minimum: 0, maximum: 140),
                                                   .number(value: nil, minimum: 0, maximum: 140)])
        let fruit = try #require(data.variable(section: "Food", variable: "Fruit&veg portions / day"))
        #expect(fruit.kind == .number(value: nil, minimum: 0, maximum: 10))
    }

    // Scenario: Valores inválidos e elemento desconhecido
    @Test func invalidValuesBecomeNilAndUnknownElementsAreSkipped() throws {
        let xml = #"<Data><Cat ID="A" Descr=""><Num Min="" Max="" ID="n" Descr="">abc</Num><Date ID="d" Descr="">31/02/2020</Date><Bool ID="b" Descr="" /></Cat></Data>"#
        let section = try #require(try AdditionalDataXML.decode(xml).section("A"))
        #expect(section.variables.map(\.identifier) == ["n", "d"])
        #expect(section.variables.map(\.kind) == [.number(value: nil, minimum: nil, maximum: nil), .date(nil)])
    }

    // Scenario: Atributo obrigatório ausente
    @Test func missingDescrAttributeThrows() {
        #expect(throws: AdditionalDataXMLError.self) {
            try AdditionalDataXML.decode(#"<Data><Cat ID="A"><Txt ID="t" Descr=""></Txt></Cat></Data>"#)
        }
    }

    // Scenario: Texto ausente
    @Test func nilOrEmptyXMLDecodesToEmptyData() throws {
        let fromNil = try AdditionalDataXML.decode(nil)
        let fromEmpty = try AdditionalDataXML.decode("")
        #expect(fromNil.sections.isEmpty)
        #expect(fromEmpty.sections.isEmpty)
        #expect(AdditionalDataXML.encode(fromNil) == "<Data />")
        #expect(AdditionalDataXML.encode(fromEmpty) == "<Data />")
    }

    // Scenario: Ida e volta do modelo padrão
    @Test func templateRoundTripIsByteIdentical() throws {
        let xml = try iaTemplateFixture()
        #expect(xml.hasPrefix(#"<Data><Cat ID="Maturation" Descr="">"#))
        #expect(AdditionalDataXML.encode(try AdditionalDataXML.decode(xml)) == xml)
    }

    // Scenario: Dados sem seções e seção sem variáveis
    @Test func emptyDataAndEmptySectionSerializeSelfClosing() {
        #expect(AdditionalDataXML.encode(AdditionalData()) == "<Data />")
        let oneSection = AdditionalData(sections: [AdditionalDataSection(identifier: "A")])
        #expect(AdditionalDataXML.encode(oneSection) == #"<Data><Cat ID="A" Descr="" /></Data>"#)
    }

    // Scenario: Número e data gravados
    @Test func numberUsesPointAndDateUsesOriginalFormat() throws {
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: "S", variables: [
            AdditionalDataVariable(identifier: "n", kind: .number(value: d("1.5"), minimum: nil, maximum: nil)),
            AdditionalDataVariable(identifier: "d", kind: .date(localDate(2016, 3, 15))),
        ])])
        let xml = AdditionalDataXML.encode(data)
        #expect(xml.contains(#"ID="n" Descr="">1.5</Num>"#))
        #expect(xml.contains(#"<Date ID="d" Descr="">15-03-2016 00:00:00</Date>"#))
        #expect(try AdditionalDataXML.decode(xml) == data)
    }

    // Scenario: Número com vírgula na leitura
    @Test func decoderAcceptsCommaDecimals() throws {
        let xml = #"<Data><Cat ID="A" Descr=""><Num Min="0,5" Max="" ID="n" Descr="">2,25</Num></Cat></Data>"#
        let variable = try #require(try AdditionalDataXML.decode(xml).variable(section: "A", variable: "n"))
        #expect(variable.kind == .number(value: d("2.25"), minimum: d("0.5"), maximum: nil))
    }
}
