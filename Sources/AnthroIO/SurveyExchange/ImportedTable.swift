/// Tabela intermediária de texto, como o `DataTable` do original (design D1).
public struct ImportedTable: Equatable, Sendable {
    public var columns: [String]
    public var rows: [[String]]

    public init(columns: [String], rows: [[String]]) {
        self.columns = columns
        self.rows = rows
    }
}
