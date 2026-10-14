import AnthroStore
import Testing

/// Laço interno de `NameMatcher` (tarefa 2.1 da add-individual-assessment, design D5).
@Suite("NameMatcher: unidades")
struct NameMatcherUnitTests {
    @Test func asteriscoValeQualquerSequenciaInclusiveVazia() {
        #expect(NameMatcher.matches(pattern: "L*", value: "L"))
        #expect(NameMatcher.matches(pattern: "*ez", value: "Lopez"))
        #expect(NameMatcher.matches(pattern: "L*z", value: "Lopez"))
    }

    @Test func interrogacaoValeExatamenteUmCaractere() {
        #expect(NameMatcher.matches(pattern: "?na", value: "Ana"))
        #expect(!NameMatcher.matches(pattern: "?na", value: "Anna"))
        #expect(!NameMatcher.matches(pattern: "?na", value: "na"))
    }

    @Test func padraoAncoradoNasDuasPontas() {
        #expect(!NameMatcher.matches(pattern: "Lop", value: "Lopez"))
        #expect(!NameMatcher.matches(pattern: "pez", value: "Lopez"))
    }

    @Test func metacaracteresDeRegexSaoLiterais() {
        #expect(NameMatcher.matches(pattern: "D'Ávila (2)", value: "d'ávila (2)"))
        #expect(!NameMatcher.matches(pattern: "A.a", value: "Ana"))
        #expect(NameMatcher.matches(pattern: "A.a", value: "A.a"))
        #expect(!NameMatcher.matches(pattern: "[A]na", value: "Ana"))
    }

    @Test func maiusculasUnicodeDobradasAcentosDistintos() {
        #expect(NameMatcher.matches(pattern: "ÉRICA", value: "érica"))
        #expect(!NameMatcher.matches(pattern: "erica", value: "Érica"))
        #expect(NameMatcher.matches(pattern: "çã*", value: "ÇÃO"))
    }

    @Test func valorNuloNaoCasa() {
        #expect(!NameMatcher.matches(pattern: "*", value: nil))
    }
}
