import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários de leitura de valores na importação (change add-individual-import-export).
@Suite("individual-data-exchange: leitura de campos")
struct FieldParserTests {
    // Scenario: Variações de sexo aceitas
    @Test func variacoesDeSexoAceitasNaImportacao() throws {
        #expect(try FieldParser.sex("F") == .girl)
        #expect(try FieldParser.sex("2") == .girl)
        #expect(try FieldParser.sex("Male") == .boy)
        let children = try ChildXML.read(ExchangeFixtures.xml(
            ExchangeFixtures.child(["Sex": "F"]) + ExchangeFixtures.child(["Sex": "2"]) + ExchangeFixtures.child(["Sex": "Male"])))
        #expect(children.map(\.sex) == [.girl, .girl, .boy])
    }

    // Scenario: Decimal com vírgula
    @Test func decimalComVirgulaEhLidoComoPonto() throws {
        #expect(try FieldParser.decimal("16,5", nullable: false, unsigned: true) == d("16.5"))
    }

    // Scenario: Formatos de data aceitos
    @Test func formatosDeDataAceitosDescartamHora() throws {
        for text in ["15-03-2016 10:20:00", "15/03/2016", "20160315"] {
            let date = try FieldParser.date(text, nullable: false)
            #expect(date == day("2016-03-15"), "\(text)")
        }
    }
}
