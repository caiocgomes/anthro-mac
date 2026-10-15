import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários da exportação TXT e CSV do inquérito (change add-survey-import-export).
@Suite("survey-data-exchange: exportação delimitada do inquérito")
struct SurveyDelimitedExportTests {
    private typealias F = SurveyExchangeFixtures

    private func cell(_ lines: [String], _ name: String, separator: String) -> String? {
        let header = lines.first?.components(separatedBy: separator) ?? []
        let row = lines.dropFirst().first?.components(separatedBy: separator) ?? []
        return header.firstIndex(of: name).flatMap { row.indices.contains($0) ? row[$0] : nil }
    }

    // Scenario: Cabeçalho do inquérito
    @Test func cabecalhoDoInqueritoTem18ColunasNaOrdem() {
        let lines = F.lines(SurveyDelimitedExport.data(ExchangeSurvey(survey: Survey(name: "A"), records: [F.record()]),
                                                       resultsEngine: nil, format: .semicolonCSV))
        #expect(lines.first == "Date;Cluster;Team;DisplayID;Household;WeightingFactor;FirstName;LastName;DateOfBirth;DateOfBirthIsApprox;Age;Sex;Weight;Height;IsRecumbent;HasOedema;Notes;CreatedBy")
    }

    // Scenario: Cabeçalho com resultados e dados adicionais
    @Test func cabecalhoComResultadosEDadosAdicionaisTem23Campos() throws {
        let definition = #"<Data><Cat ID="Imported" Descr=""><Txt ID="escola" Descr=""></Txt></Cat></Data>"#
        let survey = ExchangeSurvey(survey: Survey(name: "A", additionalDataDefinitionXML: definition), records: [F.record()])
        let lines = F.lines(SurveyDelimitedExport.data(survey, resultsEngine: try AnthroEngine.shared(), format: .tabText))
        let header = lines.first?.components(separatedBy: "\t") ?? []
        #expect(header.count == 23)
        #expect(Array(header.suffix(5)) == ["WAZ", "HAZ", "BAZ", "BMI", "escola"])
    }

    // Scenario: Idade calculada pelas datas
    @Test func idadeCalculadaPelasDatasComDezCasas() {
        let lines = F.lines(SurveyDelimitedExport.data(ExchangeSurvey(survey: Survey(name: "A"), records: [F.record()]),
                                                       resultsEngine: nil, format: .semicolonCSV))
        #expect(cell(lines, "Age", separator: ";") == "60,5503080082")
    }

    // Scenario: Idade desconhecida
    @Test func idadeDesconhecidaSaiVazia() {
        let record = F.record(birth: nil)
        let lines = F.lines(SurveyDelimitedExport.data(ExchangeSurvey(survey: Survey(name: "A"), records: [record]),
                                                       resultsEngine: nil, format: .semicolonCSV))
        #expect(lines.count == 2)
        #expect(cell(lines, "Age", separator: ";") == "")
    }
}
