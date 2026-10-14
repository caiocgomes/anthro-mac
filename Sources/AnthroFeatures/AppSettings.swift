import Foundation
import Observation

/// Opções do original usadas pelo app, persistidas em `UserDefaults`.
@MainActor
@Observable
public final class AppSettings {
    private enum Key {
        static let useEnterForNextControl = "useEnterForNextControl"
        static let autoAssignChildID = "autoAssignChildID"
        static let lastSection = "lastSection"
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// Enter avança para o próximo campo (`UseEnterForNextControl` do original, padrão `True`).
    public var useEnterForNextControl: Bool {
        didSet { defaults.set(useEnterForNextControl, forKey: Key.useEnterForNextControl) }
    }

    /// ID de criança atribuído automaticamente (`IAAutoID` do original, padrão `True`).
    public var autoAssignChildID: Bool {
        didSet { defaults.set(autoAssignChildID, forKey: Key.autoAssignChildID) }
    }

    public var lastSection: AppSection {
        didSet { defaults.set(lastSection.rawValue, forKey: Key.lastSection) }
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.useEnterForNextControl: true,
            Key.autoAssignChildID: true,
        ])
        useEnterForNextControl = defaults.bool(forKey: Key.useEnterForNextControl)
        autoAssignChildID = defaults.bool(forKey: Key.autoAssignChildID)
        lastSection = defaults.string(forKey: Key.lastSection).flatMap(AppSection.init(rawValue:)) ?? .calculator
    }
}
