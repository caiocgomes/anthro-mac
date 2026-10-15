import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários de formatação, arquivo e nomes do relatório (change add-survey-analysis).
@Suite("survey-reports: formato e arquivo")
struct ReportFileTests {
    // Scenario: Intervalos calculados
    @Test func intervalosCalculadosFormatados() {
        #expect(ReportFormat.interval(.interval(low: d("4.7"), high: d("55.9"))) == "(4,7%, 55,9%)")
        #expect(ReportFormat.interval(.interval(low: 0, high: 100)) == "(0%, 100%)")
    }

    // Scenario: Valores especiais
    @Test func valoresEspeciaisFormatados() {
        #expect(ReportFormat.interval(.unavailable) == "(-, -)")
        #expect(ReportFormat.interval(.singleCluster) == "(., .)")
        #expect(ReportFormat.number(nil) == " ")
        #expect(ReportFormat.number(d("-0.00")) == "0")
    }

    // Scenario: Bytes e nomes do arquivo
    @Test func bytesENomesDoArquivo() throws {
        let report = try SurveyReportWriter.standardReport(records: ReportFixtures.tenChildren(), options: .default,
                                                           improvedClusterAnalysis: false)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("anthro-report-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent(SurveyReportWriter.defaultFileName(surveyName: "Escola A", kind: .standard(improvedClusterAnalysis: false)))
        try SurveyReportWriter.write(report, to: url)
        let data = try #require(try? Data(contentsOf: url))
        #expect(Array(data.prefix(2)) == [0xFF, 0xFE])
        let text = try #require(String(data: data.dropFirst(2), encoding: .utf16LittleEndian))
        #expect(text.contains("\r\n"))
        let scalars = Array(text.unicodeScalars)
        let loneBreaks = scalars.indices.filter { index in
            (scalars[index] == "\n" && (index == 0 || scalars[index - 1] != "\r"))
                || (scalars[index] == "\r" && (index + 1 == scalars.count || scalars[index + 1] != "\n"))
        }
        #expect(loneBreaks.isEmpty)
        #expect(SurveyReportWriter.defaultFileName(surveyName: "Escola A", kind: .standard(improvedClusterAnalysis: false)) == "Escola A_standard.txt")
        #expect(SurveyReportWriter.defaultFileName(surveyName: "Escola A", kind: .standard(improvedClusterAnalysis: true)) == "Escola A_standard_cluster.txt")
        #expect(SurveyReportWriter.defaultFileName(surveyName: "Escola A", kind: .estimates) == "Escola A_estimates.txt")
    }
}
