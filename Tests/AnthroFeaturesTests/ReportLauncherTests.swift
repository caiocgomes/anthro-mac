import AnthroFeatures
import Foundation
import Testing

/// Cenários da abertura do relatório gravado (change add-survey-analysis).
@Suite("survey-reports: abertura do relatório")
struct ReportLauncherTests {
    private let file = URL(fileURLWithPath: "/tmp/Escola A_standard.txt")

    // Scenario: Excel instalado
    @Test func excelInstaladoAbreNoExcel() {
        let opener = RecordingReportOpener()
        let excel = URL(fileURLWithPath: "/Applications/Microsoft Excel.app")
        opener.installed = [ReportLauncher.excelBundleID: excel,
                            ReportLauncher.numbersBundleID: URL(fileURLWithPath: "/Applications/Numbers.app")]
        #expect(ReportLauncher.open(file, using: opener) == "com.microsoft.Excel")
        #expect(opener.opened.map(\.application) == [excel])
        #expect(opener.opened.map(\.file) == [file])
    }

    // Scenario: Nenhuma planilha instalada
    @Test func nenhumaPlanilhaInstaladaUsaPadrao() {
        let opener = RecordingReportOpener()
        ReportLauncher.open(file, using: opener)
        #expect(opener.opened.count == 1)
        #expect(opener.opened.first?.application == nil)
    }
}
