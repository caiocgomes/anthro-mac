import Foundation
import Observation

/// Opções do original usadas pelo app, persistidas em `UserDefaults`.
@MainActor
@Observable
public final class AppSettings {
    public var useEnterForNextControl: Bool = false
    public var autoAssignChildID: Bool = false
    public var lastSection: AppSection = .calculator

    public init(defaults: UserDefaults) {}
}
