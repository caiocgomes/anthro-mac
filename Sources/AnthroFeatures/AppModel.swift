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
        select(section)
        return true
    }
}
