import AnthroStore
import Observation

/// Estado da janela principal: seção ativa e atalhos ⌘1 a ⌘3 (design D9).
@MainActor
@Observable
public final class AppModel {
    public let settings: AppSettings
    public let store: StoreController

    public var selectedSection: AppSection {
        didSet { settings.lastSection = selectedSection }
    }

    /// Módulo aberto que tem de perguntar antes de sair, se houver alterações pendentes.
    @ObservationIgnored public weak var unsavedChangesGuard: UnsavedChangesGuard?

    /// Estado de módulo que sobrevive ao fechamento da janela (a ficha em edição da Avaliação individual), para que as
    /// alterações pendentes não se percam e o encerramento do app ainda pergunte.
    @ObservationIgnored public var moduleSessions: [AppSection: AnyObject] = [:]

    /// Módulo pedido enquanto o guarda tem alterações pendentes; a janela mostra o diálogo de `AskForSave`.
    public private(set) var pendingSection: AppSection?

    /// Troca de módulo: com alterações pendentes no módulo aberto, guarda o pedido até a decisão da usuária.
    public func requestSection(_ section: AppSection) {
        guard section != selectedSection else { return }
        if let unsavedChangesGuard, unsavedChangesGuard.hasUnsavedChanges {
            pendingSection = section
        } else {
            select(section)
        }
    }

    /// Aplica a decisão do diálogo ao pedido pendente: salvar ou descartar trocam de módulo; cancelar fica.
    public func resolvePendingSection(_ decision: UnsavedChangesDecision) throws {
        guard let section = pendingSection else { return }
        pendingSection = nil
        if try unsavedChangesGuard?.proceedAfterUnsavedChanges(decision) ?? true {
            select(section)
        }
    }

    public init(settings: AppSettings, store: StoreController) {
        self.settings = settings
        self.store = store
        selectedSection = settings.lastSection
    }

    public func select(_ section: AppSection) {
        selectedSection = section
    }

    /// Seleciona o módulo do atalho ⌘`number`; devolve `false` sem mudar nada fora de 1 a 3.
    public func handleShortcut(number: Int) -> Bool {
        guard let section = AppSection.allCases.first(where: { $0.shortcutNumber == number }) else {
            return false
        }
        requestSection(section)
        return true
    }
}
