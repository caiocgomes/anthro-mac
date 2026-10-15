import Foundation

/// `External.ParseDBFFile` lido por bytes (design D8).
public enum DBFParser {
    public static func parse(_ data: Data) throws(ImportFailure) -> ImportedTable {
        ImportedTable(columns: [], rows: [])
    }
}
