/// Tabela intermediária de texto, como o `DataTable` do original (design D1).
public struct ImportedTable: Equatable, Sendable {
    public var columns: [String]
    public var rows: [[String]]

    public init(columns: [String], rows: [[String]]) {
        self.columns = columns
        self.rows = rows
    }
}

/// Nomes de coluna como `DataColumnCollection`: comparação sem diferenciar maiúsculas e `Column1`, `Column2`... para
/// nome vazio, o menor ainda não usado (`GetNextColumnHeader`).
enum ColumnNames {
    static func contains(_ columns: [String], _ name: String) -> Bool {
        columns.contains { $0.compare(name, options: .caseInsensitive) == .orderedSame }
    }

    static func next(_ columns: [String]) -> String {
        var number = 1
        while contains(columns, "Column\(number)") { number += 1 }
        return "Column\(number)"
    }

    /// REC e DBF: `Columns.Add` dá o nome padrão ao vazio e recusa o repetido, o que derruba o arquivo no original.
    static func strict(_ names: [String]) throws(ImportFailure) -> [String] {
        var columns: [String] = []
        for name in names {
            if name.isEmpty {
                columns.append(next(columns))
            } else if contains(columns, name) {
                throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
            } else {
                columns.append(name)
            }
        }
        return columns
    }
}
