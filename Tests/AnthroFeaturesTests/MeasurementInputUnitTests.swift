import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `MeasurementInput` (task 1.2).
@Suite("MeasurementInput: unidades")
struct MeasurementInputUnitTests {
    @Test func truncamentoEmDirecaoAZero() {
        #expect(MeasurementInput.truncate(num("20.129"), places: 2) == num("20.12"))
        #expect(MeasurementInput.truncate(num("-1.239"), places: 2) == num("-1.23"))
        #expect(MeasurementInput.truncate(num("7"), places: 0) == 7)
    }

    @Test func mensagensDoAviso() {
        #expect(MeasurementInput.Outcome.outOfRange(num("38")...num("230")).issueMessage == "Fora do intervalo: 38,00 a 230,00")
        #expect(MeasurementInput.Outcome.invalid.issueMessage == "Valor inválido")
        #expect(MeasurementInput.Outcome.empty.issueMessage == nil)
        #expect(MeasurementInput.Outcome.value(1).issueMessage == nil)
    }

    @Test func limitesInclusivos() {
        #expect(MeasurementInput.evaluate("0,9", range: num("0.9")...num("275")) == .value(num("0.9")))
        #expect(MeasurementInput.evaluate("275", range: num("0.9")...num("275")) == .value(275))
    }
}
