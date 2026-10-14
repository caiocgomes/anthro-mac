import AnthroFeatures
import Foundation
import Testing

/// Cenários do helper compartilhado `MeasurementInput` (capability anthropometric-calculator).
@Suite("anthropometric-calculator: MeasurementInput")
struct MeasurementInputTests {
    private let weightRange = num("0.9")...num("275")
    private let lengthRange = num("38")...num("230")

    // Scenario: Helper trunca texto válido
    @Test func helperTruncaTextoValido() {
        #expect(MeasurementInput.evaluate("20,129", range: weightRange) == .value(num("20.12")))
        #expect(MeasurementInput.evaluate("20.5", range: weightRange) == .value(num("20.5")))
    }

    // Scenario: Helper aponta valor fora do intervalo
    @Test func helperApontaValorForaDoIntervalo() {
        #expect(MeasurementInput.evaluate("300", range: weightRange) == .outOfRange(weightRange))
        #expect(MeasurementInput.evaluate("0,5", range: weightRange) == .outOfRange(weightRange))
        #expect(MeasurementInput.parse("300", range: weightRange) == nil)
        #expect(MeasurementInput.parse("0,5", range: weightRange) == nil)
    }

    // Scenario: Helper aponta texto inválido e vazio
    @Test func helperApontaTextoInvalidoEVazio() {
        #expect(MeasurementInput.evaluate("12,3,4", range: lengthRange) == .invalid)
        #expect(MeasurementInput.evaluate("abc", range: lengthRange) == .invalid)
        #expect(MeasurementInput.evaluate("  ", range: lengthRange) == .empty)
    }
}
