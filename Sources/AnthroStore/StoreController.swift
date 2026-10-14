import Foundation
import Observation

/// Abertura do banco com backup, integridade e migração, nesta ordem (design D5).
@MainActor
@Observable
public final class StoreController {
    public enum State: Equatable {
        case closed
        case ready
        case corrupted(String)
        case failed(String)
    }

    public private(set) var state: State = .closed
    public private(set) var database: AnthroDatabase? = nil

    public init(directory: URL, now: @escaping () -> Date = Date.init) {}

    public func openOnLaunch() {}

    public func restoreLatestBackup() throws {}

    public func exportCopy(to url: URL) throws {}
}
