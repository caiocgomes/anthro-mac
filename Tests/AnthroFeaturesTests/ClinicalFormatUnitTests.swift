import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `ClinicalFormat` (task 1.3).
@Suite("ClinicalFormat: unidades")
struct ClinicalFormatUnitTests {
    @Test func semSeparadorDeMilhar() {
        #expect(ClinicalFormat.string(Decimal(string: "1234.5")!, places: 1) == "1234,5")
    }

    @Test func leituraComSinalNegativo() {
        #expect(ClinicalFormat.parseDecimal("-2,5") == Decimal(string: "-2.5")!)
    }
}
