import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários de codificação de valores exportados (change add-individual-import-export).
@Suite("individual-data-exchange: escrita de campos")
struct FieldWriterTests {
    // Scenario: Data, sexo e medida
    @Test func dataSexoEMedidaUsamCodigosDoOriginal() {
        #expect(FieldWriter.date(day("2016-03-15")) == "15-03-2016 00:00:00")
        #expect(FieldWriter.sex(.girl) == "0")
        #expect(FieldWriter.sex(.boy) == "1")
        #expect(FieldWriter.measureType(false) == "0")
        #expect(FieldWriter.measureType(true) == "1")
        #expect(FieldWriter.boolean(false) == "0")
        #expect(FieldWriter.boolean(true) == "1")
        #expect(FieldWriter.date(nil) == "")
    }

    // Scenario: Decimal em CSV e em XML
    @Test func decimalEmCsvUsaVirgulaEEmXmlUsaPonto() throws {
        #expect(FieldWriter.decimal(d("16.50"), style: .comma) == "16,5")
        #expect(FieldWriter.decimal(d("16.50"), style: .point) == "16.5")
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01", weight: "16.50", height: "110")])
        let csv = ExchangeFixtures.table(ChildDelimitedExport.data([child], additionalDefinition: AdditionalData(),
                                                                   includeResults: false, format: .semicolonCSV),
                                         separator: ";")
        #expect(ExchangeFixtures.cell(csv, "Weight") == "16,5")
        let xml = String(decoding: ChildXML.data([child], includeResults: false), as: UTF8.self)
        #expect(xml.contains("Weight=\"16.5\""))
    }
}
