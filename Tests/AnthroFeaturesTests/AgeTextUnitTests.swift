import AnthroFeatures
import Testing

/// Laço interno de `AgeText` (task 1.1).
@Suite("AgeText: unidades")
struct AgeTextUnitTests {
    @Test func dozeMesesUsaFormatoLongoERecemNascidoCurto() {
        #expect(AgeText.localized(months: 12) == "Idade: 1a 0m (12m)")
        #expect(AgeText.localized(months: 11) == "Idade: 11m")
        #expect(AgeText.localized(months: 0) == "Idade: 0m")
    }
}
