import AnthroCore
import Foundation
import Testing

/// Laço interno da carga das tabelas (task 1.2).
@Suite("GrowthReferenceTables: unidades")
struct GrowthReferenceTablesUnitTests {
    private func csv(_ ages: ClosedRange<Int>, replacing line: Int? = nil, with text: String = "") -> String {
        var lines = ["sex,age,l,m,s"]
        for sex in [1, 2] {
            for age in ages { lines.append("\(sex),\(age),1,10,0.1") }
        }
        if let line { lines[line - 1] = text }
        return lines.joined(separator: "\n")
    }

    @Test func linhaMalformadaApontaArquivoELinha() {
        let standards: [Indicator: String] = [
            .weightForAge: csv(0...1856, replacing: 3, with: "1,1,abc,10,0.1"),
            .lengthOrHeightForAge: csv(0...1856),
            .bmiForAge: csv(0...1856),
        ]
        let reference: [Indicator: String] = [
            .weightForAge: csv(60...121), .lengthOrHeightForAge: csv(60...229), .bmiForAge: csv(60...229),
        ]
        #expect(throws: ReferenceDataError.malformedRow(file: "std-wfa", line: 3)) {
            try GrowthReferenceTables.load(standardsCSV: standards, referenceCSV: reference)
        }
    }
}
