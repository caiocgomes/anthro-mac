import AnthroIO
import Foundation
import Testing

/// Cenários da escolha do leitor pela extensão (change add-survey-import-export).
@Suite("survey-data-exchange: leitor pela extensão")
struct SurveyFileKindTests {
    // Scenario: Extensões conhecidas
    @Test func extensoesConhecidasEscolhemOLeitor() {
        let kinds = ["a.TXT", "b.csv", "c.Rec", "d.dbf", "e.xml"].map { SurveyFileKind.forFileExtension(URL(fileURLWithPath: $0).pathExtension) }
        #expect(kinds == [.delimited(fallbackSeparator: "\t"), .delimited(fallbackSeparator: ";"), .rec, .dbf, .xml])
    }

    // Scenario: Extensão desconhecida vira XML
    @Test func extensaoDesconhecidaViraXmlEFalha() {
        #expect(SurveyFileKind.forFileExtension("dat") == .xml)
        expectInvalidStructure { () throws(ImportFailure) in _ = try SurveyXML.read(Data("Sex;Weight".utf8)) }
    }
}
