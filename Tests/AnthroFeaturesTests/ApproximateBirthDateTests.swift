import AnthroFeatures
import Foundation
import Testing

/// Cenários do helper compartilhado `ApproximateBirthDate` (capability anthropometric-calculator).
@Suite("anthropometric-calculator: ApproximateBirthDate")
struct ApproximateBirthDateTests {
    private let visit = day(2026, 10, 14)

    // Scenario: Helper nunca sorteia o último dia
    @Test func helperNuncaSorteiaOUltimoDia() {
        var ranges: [Range<Int>] = []
        let result = ApproximateBirthDate.randomized(day(2021, 2, 10)) { ranges.append($0); return $0.upperBound - 1 }
        #expect(ranges == [1..<28])
        #expect(ymd(result) == "2021-02-27")
    }

    // Scenario: Helper em fevereiro bissexto
    @Test func helperEmFevereiroBissextoUsaIntervaloDe29() {
        var ranges: [Range<Int>] = []
        let result = ApproximateBirthDate.randomized(day(2024, 2, 10)) { ranges.append($0); return $0.lowerBound }
        #expect(ranges == [1..<29])
        #expect(ymd(result) == "2024-02-01")
    }

    // Scenario: Helper desfaz troca de dia
    @Test func helperDesfazTrocaDeDiaSemSortear() {
        var ranges: [Range<Int>] = []
        let result = ApproximateBirthDate.adjusted(previous: day(2021, 2, 1), proposed: day(2021, 2, 15), isApprox: true,
                                                   upperBound: visit) { ranges.append($0); return $0.lowerBound }
        #expect(ymd(result) == "2021-02-01")
        #expect(ranges.isEmpty)
    }

    // Scenario: Helper aceita troca de mês e sorteia de novo
    @Test func helperAceitaTrocaDeMesESorteiaDeNovo() {
        var ranges: [Range<Int>] = []
        let result = ApproximateBirthDate.adjusted(previous: day(2021, 2, 1), proposed: day(2021, 3, 1), isApprox: true,
                                                   upperBound: visit) { ranges.append($0); return 9 }
        #expect(ranges == [1..<31])
        #expect(ymd(result) == "2021-03-09")
    }

    // Scenario: Helper sem data aproximada só limita pela visita
    @Test func helperSemDataAproximadaSoLimitaPelaVisita() {
        let earlier = ApproximateBirthDate.adjusted(previous: day(2020, 10, 14), proposed: day(2020, 1, 1), isApprox: false,
                                                    upperBound: visit) { $0.lowerBound }
        let later = ApproximateBirthDate.adjusted(previous: day(2020, 10, 14), proposed: day(2027, 1, 1), isApprox: false,
                                                  upperBound: visit) { $0.lowerBound }
        #expect(ymd(earlier) == "2020-01-01")
        #expect(ymd(later) == "2026-10-14")
    }
}
