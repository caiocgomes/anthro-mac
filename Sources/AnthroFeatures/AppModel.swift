import AnthroStore
import Observation

/// Estado da janela principal: seção ativa e atalhos ⌘1 a ⌘3 (design D9).
@MainActor
@Observable
public final class AppModel {
    public var selectedSection: AppSection = .calculator

    public init(settings: AppSettings, store: StoreController) {}

    public func select(_ section: AppSection) {}

    public func handleShortcut(number: Int) -> Bool {
        false
    }
}
