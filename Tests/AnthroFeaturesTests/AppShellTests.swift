import AnthroFeatures
import AnthroStore
import Foundation
import Testing

/// Testes de cenário da capability app-shell (change bootstrap-macos-app).
@MainActor
@Suite("app-shell")
struct AppShellTests {
    private func makeDefaults() -> UserDefaults {
        let name = "anthro-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeStore() -> StoreController {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return StoreController(directory: dir)
    }

    private func makeModel(defaults: UserDefaults) -> AppModel {
        AppModel(settings: AppSettings(defaults: defaults), store: makeStore())
    }

    // Scenario: Primeira abertura
    @Test func primeiraAberturaMostraCalculadora() {
        let model = makeModel(defaults: makeDefaults())
        #expect(AppSection.allCases.map(\.title) == [
            "Calculadora antropométrica",
            "Avaliação individual",
            "Inquérito nutricional",
        ])
        #expect(AppSection.allCases.allSatisfy { !$0.systemImage.isEmpty })
        #expect(model.selectedSection == .calculator)
    }

    // Scenario: Reabertura lembra a seção
    @Test func reaberturaLembraASecao() {
        let defaults = makeDefaults()
        let first = makeModel(defaults: defaults)
        first.select(.nutritionalSurvey)
        let second = makeModel(defaults: defaults)
        #expect(second.selectedSection == .nutritionalSurvey)
    }

    // Scenario: Atalho válido
    @Test func atalhoValidoSelecionaModulo() {
        let model = makeModel(defaults: makeDefaults())
        #expect(model.selectedSection == .calculator)
        #expect(model.handleShortcut(number: 2) == true)
        #expect(model.selectedSection == .individualAssessment)
    }

    // Scenario: Atalho fora do intervalo
    @Test func atalhoForaDoIntervaloNaoMudaSelecao() {
        let model = makeModel(defaults: makeDefaults())
        model.select(.individualAssessment)
        #expect(model.handleShortcut(number: 4) == false)
        #expect(model.handleShortcut(number: 0) == false)
        #expect(model.selectedSection == .individualAssessment)
    }

    // Scenario: Valores padrão
    @Test func configuracoesTemValoresPadraoDoOriginal() {
        let settings = AppSettings(defaults: makeDefaults())
        #expect(settings.useEnterForNextControl == true)
        #expect(settings.autoAssignChildID == true)
        #expect(settings.lastSection == .calculator)
    }

    // Scenario: Valor alterado sobrevive a nova instância
    @Test func configuracaoAlteradaSobreviveANovaInstancia() {
        let defaults = makeDefaults()
        let first = AppSettings(defaults: defaults)
        first.autoAssignChildID = false
        first.lastSection = .individualAssessment
        let second = AppSettings(defaults: defaults)
        #expect(second.autoAssignChildID == false)
        #expect(second.lastSection == .individualAssessment)
    }

    // Scenario: Catálogo sem buracos
    @Test func catalogoDeTextosSemBuracos() {
        let all = L10n.allStrings
        #expect(all.count > 20)
        #expect(all.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        #expect(L10n.notAvailable == "N/D")
    }

    // Scenario: Nome do app
    @Test func nomeDoAppEAnthroPlus() {
        #expect(L10n.appName == "AnthroPlus")
    }

    // Scenario: Conteúdo do Sobre
    @Test func sobreAtribuiAOMS() {
        #expect(L10n.About.attribution.contains("WHO AnthroPlus 1.0.4"))
        #expect(L10n.About.references.contains("2006"))
        #expect(L10n.About.references.contains("2007"))
    }

    // Scenario: Versão ausente no bundle
    @Test func versaoAusenteViraDesenvolvimento() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let withoutVersion = root.appendingPathComponent("SemVersao.bundle", isDirectory: true)
        try FileManager.default.createDirectory(
            at: withoutVersion.appendingPathComponent("Contents", isDirectory: true),
            withIntermediateDirectories: true
        )
        let bundleWithoutVersion = try #require(Bundle(url: withoutVersion))
        #expect(AboutInfo.version(bundle: bundleWithoutVersion) == "desenvolvimento")

        let withVersion = root.appendingPathComponent("ComVersao.bundle", isDirectory: true)
        let contents = withVersion.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": "local.test.\(UUID().uuidString)",
            "CFBundleShortVersionString": "1.2.3",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        let bundleWithVersion = try #require(Bundle(url: withVersion))
        #expect(AboutInfo.version(bundle: bundleWithVersion) == "1.2.3")
    }
}
