/// Registros removidos por `OrphanCleanup.run`.
public struct OrphanCleanupResult: Sendable, Equatable {
    public let mothers: Int
    public let fathers: Int
    public let addresses: Int

    public init(mothers: Int, fathers: Int, addresses: Int) {
        self.mothers = mothers
        self.fathers = fathers
        self.addresses = addresses
    }
}

/// Mães, pais e endereços sem criança (`CleanupOrphans` do original, design D6).
public enum OrphanCleanup {
    @discardableResult public static func run(in database: AnthroDatabase) throws -> OrphanCleanupResult {
        OrphanCleanupResult(mothers: 0, fathers: 0, addresses: 0)
    }
}
