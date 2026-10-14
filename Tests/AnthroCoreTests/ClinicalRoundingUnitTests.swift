import AnthroCore
import Foundation
import Testing

/// Laço interno de `ClinicalRounding` (task 2.1).
@Suite("ClinicalRounding: unidades")
struct ClinicalRoundingUnitTests {
    @Test func zeroENegativosSemEmpate() {
        #expect(ClinicalRounding.round(0, places: 2) == 0)
        #expect(ClinicalRounding.round(d("-1.234"), places: 2) == d("-1.23"))
        #expect(ClinicalRounding.round(d("-1.236"), places: 2) == d("-1.24"))
        #expect(ClinicalRounding.round(d("1872.6875"), places: 0) == 1873)
    }

    @Test func quinzeDigitosSignificativos() {
        #expect(ClinicalRounding.decimal15(1.0 / 3.0) == d("0.333333333333333"))
        #expect(ClinicalRounding.decimal15(2.0 / 3.0 * 1000) == d("666.666666666667"))
    }
}
