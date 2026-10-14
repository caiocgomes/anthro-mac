import AnthroFeatures
import Testing

/// Laço interno do autoteste (task 1.4).
@Suite("SelfTest: unidades")
struct SelfTestUnitTests {
    @Test func autotesteEncontraOsRecursosDoNucleo() {
        let outcome = SelfTest.run()
        #expect(outcome.passed)
        #expect(outcome.message == L10n.SelfTest.ok)
    }
}
