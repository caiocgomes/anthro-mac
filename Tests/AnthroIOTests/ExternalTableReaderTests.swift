import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenário da leitura externa com vírgula decimal (change add-survey-import-export).
@Suite("survey-data-exchange: leitura externa")
struct ExternalTableReaderTests {
    // Scenario: CSV com ponto e vírgula e vírgula decimal
    @Test func csvComPontoEVirgulaEVirgulaDecimalLePeso() throws {
        let table = try ExternalTableReader.read(Data("Sex;Weight;Height\r\n1;16,5;110\r\n".utf8),
                                                 kind: .delimited(fallbackSeparator: ";"))
        #expect(table.columns == ["Sex", "Weight", "Height"])
        let result = try ExternalSurveyBuilder.build(table: table, mapping: [.sex: "Sex", .weight: "Weight", .height: "Height"],
                                                     name: "escola")
        #expect(result.draft.records.first?.weight == d("16.5"))
    }
}
