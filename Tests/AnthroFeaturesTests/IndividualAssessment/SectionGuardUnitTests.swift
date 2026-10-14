import AnthroFeatures
import AnthroStore
import Foundation
import Testing

/// Laço interno da troca de módulo com alterações pendentes (tarefa 7.1 da add-individual-assessment).
@MainActor
@Suite("AppModel: troca de módulo com alterações pendentes")
struct SectionGuardUnitTests {
    final class FakeGuard: UnsavedChangesGuard {
        var hasUnsavedChanges = true
        var decisions: [UnsavedChangesDecision] = []

        func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool {
            decisions.append(decision)
            return decision != .cancel
        }
    }

    private func app() -> AppModel {
        let settings = IAFixtures.settings()
        settings.lastSection = .individualAssessment
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let model = AppModel(settings: settings, store: StoreController(directory: directory))
        return model
    }

    @Test func semPendenciasTrocaNaHora() {
        let model = app()
        let fake = FakeGuard()
        fake.hasUnsavedChanges = false
        model.unsavedChangesGuard = fake
        model.requestSection(.calculator)
        #expect(model.selectedSection == .calculator)
        #expect(model.pendingSection == nil)
    }

    @Test func comPendenciasEsperaADecisao() throws {
        let model = app()
        let fake = FakeGuard()
        model.unsavedChangesGuard = fake
        model.requestSection(.calculator)
        #expect(model.selectedSection == .individualAssessment)
        #expect(model.pendingSection == .calculator)
        try model.resolvePendingSection(.cancel)
        #expect(model.selectedSection == .individualAssessment)
        #expect(model.pendingSection == nil)
        model.requestSection(.calculator)
        try model.resolvePendingSection(.discard)
        #expect(model.selectedSection == .calculator)
        #expect(fake.decisions == [.cancel, .discard])
    }

    @Test func atalhoPassaPeloGuarda() {
        let model = app()
        let fake = FakeGuard()
        model.unsavedChangesGuard = fake
        #expect(model.handleShortcut(number: 1) == true)
        #expect(model.selectedSection == .individualAssessment)
        #expect(model.pendingSection == .calculator)
    }
}
