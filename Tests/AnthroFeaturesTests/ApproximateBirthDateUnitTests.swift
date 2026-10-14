import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `ApproximateBirthDate` (task 1.3): aritmética no calendário do usuário.
@Suite("ApproximateBirthDate: unidades")
struct ApproximateBirthDateUnitTests {
    @Test func preservaAnoEMesEmDezembro() {
        let result = ApproximateBirthDate.randomized(day(2020, 12, 25)) { _ in 7 }
        #expect(ymd(result) == "2020-12-07")
    }

    @Test func trocaDeAnoComMesmoDiaSorteiaDeNovo() {
        var ranges: [Range<Int>] = []
        let result = ApproximateBirthDate.adjusted(previous: day(2021, 2, 1), proposed: day(2022, 2, 1), isApprox: true,
                                                   upperBound: day(2026, 10, 14)) { ranges.append($0); return 3 }
        #expect(ranges == [1..<28])
        #expect(ymd(result) == "2022-02-03")
    }
}
