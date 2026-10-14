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

/// Mães, pais e endereços sem criança (`Mothers._DELETEORPHANS` e equivalentes do original, design D6).
public enum OrphanCleanup {
    @discardableResult public static func run(in database: AnthroDatabase) throws -> OrphanCleanupResult {
        try database.transaction {
            func deleteOrphans(_ table: String, _ key: String) throws -> Int {
                try database.execute(
                    "DELETE FROM \(table) WHERE NOT EXISTS (SELECT 1 FROM children WHERE children.\(key) = \(table).\(key))")
                guard case .integer(let count) = try database.query("SELECT changes() AS n").first?["n"] else { return 0 }
                return Int(count)
            }
            return OrphanCleanupResult(mothers: try deleteOrphans("mothers", "mother_id"),
                                       fathers: try deleteOrphans("fathers", "father_id"),
                                       addresses: try deleteOrphans("addresses", "address_id"))
        }
    }
}
