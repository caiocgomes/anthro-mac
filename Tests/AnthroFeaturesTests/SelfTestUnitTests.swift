import AnthroFeatures
import Testing

/// Laço interno do autoteste (task 1.4 da bootstrap-macos-app; tabelas na task 5.3 da add-anthropometric-calculator).
@Suite("SelfTest: unidades")
struct SelfTestUnitTests {
    @Test func autotesteEncontraOsRecursosDoNucleo() throws {
        var loaded = false
        let outcome = SelfTest.run(loadTables: {
            loaded = true
            return try GrowthReferenceTables.bundled()
        })
        #expect(loaded)
        #expect(outcome.passed)
        #expect(outcome.message == L10n.SelfTest.ok)
    }

    @Test func autotesteFalhaSemAsTabelasDaOMS() {
        let outcome = SelfTest.run(loadTables: { throw ReferenceDataError.missingResource("wfa-standards.csv") })
        #expect(!outcome.passed)
        #expect(outcome.message.hasPrefix(L10n.SelfTest.missingTables))
    }
}
