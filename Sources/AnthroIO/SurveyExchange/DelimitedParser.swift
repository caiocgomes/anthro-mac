/// `Delimited.ParseStream` com `DelimitedTextStream.GetNextItem` (design D5 e D6): a primeira linha é o cabeçalho;
/// nome vazio ou repetido (sem diferenciar maiúsculas, como `DataColumnCollection.Contains`) e campo excedente viram
/// `ColumnN` com o menor N livre; linha vazia é ignorada e registro curto é completado com texto vazio, em vez de
/// derrubar o arquivo como no original. Texto sem nenhuma linha é formato inválido.
public enum DelimitedParser {
    public static func parse(_ text: String, separator: Character) throws(ImportFailure) -> ImportedTable {
        var reader = FieldReader(scalars: Array(text.unicodeScalars), separator: separator.unicodeScalars.first ?? ";")
        var rows: [[String]] = []
        while let row = reader.nextRow() {
            // Linha vazia (ou só de espaços) chega como um único campo vazio.
            if row == [""] { continue }
            rows.append(row)
        }
        guard let header = rows.first else {
            throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
        }
        var columns: [String] = []
        for name in header {
            if !name.isEmpty, !contains(columns, name) {
                columns.append(name)
            } else {
                columns.append(nextColumnName(columns))
            }
        }
        var body: [[String]] = []
        for row in rows.dropFirst() {
            while row.count > columns.count { columns.append(nextColumnName(columns)) }
            body.append(row)
        }
        return ImportedTable(columns: columns,
                             rows: body.map { $0 + Array(repeating: "", count: columns.count - $0.count) })
    }

    private static func contains(_ columns: [String], _ name: String) -> Bool {
        columns.contains { $0.compare(name, options: .caseInsensitive) == .orderedSame }
    }

    /// `GetNextColumnHeader`: `Column1`, `Column2`... o menor ainda não usado.
    private static func nextColumnName(_ columns: [String]) -> String {
        var number = 1
        while contains(columns, "Column\(number)") { number += 1 }
        return "Column\(number)"
    }
}

/// `DelimitedTextStream`: lê campo a campo por escalar Unicode (CRLF é um só `Character` no Swift).
private struct FieldReader {
    let scalars: [Unicode.Scalar]
    let separator: Unicode.Scalar
    private var position = 0
    private var endOfLine = false

    init(scalars: [Unicode.Scalar], separator: Unicode.Scalar) {
        self.scalars = scalars
        self.separator = separator
    }

    /// `GetNextRow`: os campos até o fim da linha; `nil` no fim do texto.
    mutating func nextRow() -> [String]? {
        var row: [String] = []
        while let item = nextItem() { row.append(item) }
        return row.isEmpty ? nil : row
    }

    /// `GetNextItem`: espaço inicial ignorado; aspas iniciais delimitam o campo, com `""` valendo uma aspa; separador e
    /// quebra de linha dentro de aspas fazem parte do valor; CRLF, LF e CR encerram a linha.
    private mutating func nextItem() -> String? {
        if endOfLine {
            endOfLine = false
            return nil
        }
        var inQuotes = false
        var atStart = true
        var quoteClosed = false
        var value = String.UnicodeScalarView()
        while true {
            guard position < scalars.count else {
                return value.isEmpty ? nil : String(value)
            }
            let scalar = scalars[position]
            position += 1
            if (quoteClosed || !inQuotes), scalar == separator { return String(value) }
            if (atStart || quoteClosed || !inQuotes), scalar == "\n" || scalar == "\r" {
                endOfLine = true
                if scalar == "\r", position < scalars.count, scalars[position] == "\n" { position += 1 }
                return String(value)
            }
            if atStart, scalar == " " { continue }
            if atStart, scalar == "\"" {
                inQuotes = true
                atStart = false
            } else if atStart {
                atStart = false
                value.append(scalar)
            } else if scalar == "\"", inQuotes {
                if position < scalars.count, scalars[position] == "\"" {
                    value.append(scalars[position])
                    position += 1
                } else {
                    quoteClosed = true
                }
            } else {
                value.append(scalar)
            }
        }
    }
}
