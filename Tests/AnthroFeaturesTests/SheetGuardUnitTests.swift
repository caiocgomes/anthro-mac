import AnthroFeatures
import AnthroStore
import Foundation
import Testing

/// Folha de edição aberta bloqueia troca de módulo: o registro digitado na folha não é pendência que o guarda enxergue.
@MainActor
@Suite("AppModel: folha de edição aberta")
struct SheetGuardUnitTests {
    private func app() -> AppModel {
        let settings = IAFixtures.settings()
        settings.lastSection = .nutritionalSurvey
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        return AppModel(settings: settings, store: StoreController(directory: directory))
    }

    @Test func openSheetBlocksSectionChangeUntilDismissed() {
        let model = app()
        model.sheetPresented()
        #expect(model.isEditingInSheet)
        model.requestSection(.calculator)
        #expect(model.handleShortcut(number: 2) == false)
        #expect(model.selectedSection == .nutritionalSurvey)
        #expect(model.pendingSection == nil)
        model.sheetDismissed()
        #expect(model.isEditingInSheet == false)
        model.requestSection(.calculator)
        #expect(model.selectedSection == .calculator)
    }

    @Test func nestedSheetsCountUntilTheLastCloses() {
        let model = app()
        model.sheetPresented()
        model.sheetPresented()
        model.sheetDismissed()
        #expect(model.isEditingInSheet)
        model.sheetDismissed()
        model.sheetDismissed()
        #expect(model.isEditingInSheet == false)
    }
}
