import AnthroFeatures
import Foundation
import Testing

/// Laço interno da tarefa 5.2: texto do aviso com o intervalo aceito (design D7).
@MainActor
@Suite("VisitEditorModel: texto dos avisos")
struct VisitEditorWarningUnitTests {
    private func editor() throws -> VisitEditorModel {
        VisitEditorModel(dateOfBirth: IAFixtures.date("2015-01-01"), sex: .girl, existingDates: [], editing: nil,
                         engine: try AnthroEngine.shared(), today: IAFixtures.date("2021-09-01"))
    }

    @Test func avisoDeValorIlegivelNomeiaOIntervalo() throws {
        let e = try editor()
        e.weightText = "abc"
        #expect(e.weightWarning == "Valor inválido; intervalo aceito: 0,90 a 275,00")
        e.lengthOrHeightText = "1,2,3"
        #expect(e.lengthOrHeightWarning == "Valor inválido; intervalo aceito: 38,00 a 230,00")
    }

    @Test func avisoForaDoIntervaloNomeiaOIntervalo() throws {
        let e = try editor()
        e.lengthOrHeightText = "231"
        #expect(e.lengthOrHeightWarning == "Fora do intervalo: 38,00 a 230,00")
    }

    @Test func campoVazioOuValidoNaoTemAviso() throws {
        let e = try editor()
        e.weightText = ""
        e.lengthOrHeightText = "110"
        #expect(e.weightWarning == nil)
        #expect(e.lengthOrHeightWarning == nil)
    }
}
