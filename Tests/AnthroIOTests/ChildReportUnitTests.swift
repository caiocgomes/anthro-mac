import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("individual-data-exchange: relatório (unitários)")
struct ChildReportUnitTests {
    @Test func visitsAreListedChronologicallyAndFootnoteCloses() {
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-10-01", weight: "19"),
                                                  ExchangeFixtures.visit("2021-04-01", weight: "18")])
        let lines = ChildReport.text(for: child).components(separatedBy: "\r\n")
        let visitLines = lines.filter { $0.components(separatedBy: "\t").count == 12 }.dropFirst()
        #expect(visitLines.map { $0.components(separatedBy: "\t")[1] } == ["01/04/2021", "01/10/2021"])
        #expect(lines.last == ChildReport.Labels.footnote)
        #expect(lines.first == "Avaliação individual")
        #expect(lines.contains("Feminino"))
    }

    @Test func missingMeasuresLeaveEmptyFields() {
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01")])
        let line = ChildReport.text(for: child).components(separatedBy: "\r\n")
            .filter { $0.components(separatedBy: "\t").count == 12 }.last?.components(separatedBy: "\t")
        #expect(line?[3] == "")
        #expect(line?[6] == "")
        #expect(line?[9] == "")
    }

    @Test func fileNameJoinsAvailableNamesAndAvoidsPathCharacters() {
        #expect(ChildReport.suggestedFileName(for: ExchangeFixtures.ana()) == "Silva, Ana.txt")
        #expect(ChildReport.suggestedFileName(for: ExchangeChild(lastName: "Souza", dateOfBirth: day("2016-03-15"), sex: .boy))
            == "Souza.txt")
        #expect(ChildReport.suggestedFileName(for: ExchangeChild(dateOfBirth: day("2016-03-15"), sex: .boy))
            == "Avaliação individual.txt")
        #expect(ChildReport.suggestedFileName(for: ExchangeFixtures.ana(lastName: "Silva/Souza")) == "Silva-Souza, Ana.txt")
    }
}
