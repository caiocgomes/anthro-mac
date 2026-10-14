import AnthroCore
import Foundation
import Testing

/// Laço interno de `ZScore` (task 2.4).
@Suite("ZScore: unidades")
struct ZScoreUnitTests {
    /// IMC de meninos aos 61 meses: L negativo.
    private let bmiBoy61 = LMS(l: d("-0.7387"), m: d("15.2641"), s: d("0.08390"))

    @Test func lNegativoNaMedianaEmMais1Dp() throws {
        #expect(ZScore.lms(d("15.2641"), bmiBoy61, restricted: true) == 0)
        let plusOne = d("15.2641") * d("1.0904741597")  // (1 + L S)^(1/L) com L = -0.7387, S = 0.0839
        #expect(ClinicalRounding.round(ZScore.lms(plusOne, bmiBoy61, restricted: true), places: 2) == d("1.00"))
    }

    @Test func zExatamenteTresNaoMudaDeRamo() {
        #expect(ClinicalRounding.round(ZScore.centile(-3), places: 1) == d("0.1"))
        #expect(ZScore.centile(d("3.00")) != nil)
        #expect(ZScore.centile(d("-3.00")) != nil)
    }
}
