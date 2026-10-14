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

/// Registros que a limpeza de órfãos preserva, mesmo sem criança gravada: os ligados à ficha aberta e ainda não salva.
public struct OrphanCleanupKeep: Sendable, Equatable {
    public var motherIDs: Set<Int64>
    public var fatherIDs: Set<Int64>
    public var addressIDs: Set<Int64>

    public init(motherIDs: Set<Int64> = [], fatherIDs: Set<Int64> = [], addressIDs: Set<Int64> = []) {
        self.motherIDs = motherIDs
        self.fatherIDs = fatherIDs
        self.addressIDs = addressIDs
    }
}

/// Mães, pais e endereços sem criança (`Mothers._DELETEORPHANS` e equivalentes do original, design D6).
public enum OrphanCleanup {
    @discardableResult
    public static func run(in database: AnthroDatabase, keeping: OrphanCleanupKeep = OrphanCleanupKeep()) throws -> OrphanCleanupResult {
        try database.transaction {
            func deleteOrphans(_ table: String, _ key: String, keep: Set<Int64>) throws -> Int {
                let kept = keep.isEmpty ? "" : " AND \(key) NOT IN (\(keep.sorted().map(String.init).joined(separator: ", ")))"
                try database.execute(
                    "DELETE FROM \(table) WHERE NOT EXISTS (SELECT 1 FROM children WHERE children.\(key) = \(table).\(key))\(kept)")
                guard case .integer(let count) = try database.query("SELECT changes() AS n").first?["n"] else { return 0 }
                return Int(count)
            }
            return OrphanCleanupResult(mothers: try deleteOrphans("mothers", "mother_id", keep: keeping.motherIDs),
                                       fathers: try deleteOrphans("fathers", "father_id", keep: keeping.fatherIDs),
                                       addresses: try deleteOrphans("addresses", "address_id", keep: keeping.addressIDs))
        }
    }
}
