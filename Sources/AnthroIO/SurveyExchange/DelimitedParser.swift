/// `Delimited.ParseStream` com `DelimitedTextStream.GetNextItem` (design D5 e D6): a primeira linha é o cabeçalho;
/// nome vazio ou repetido (sem diferenciar maiúsculas, como `DataColumnCollection.Contains`) e campo excedente viram
/// `ColumnN` com o menor N livre; linha vazia ou só de campos vazios é ignorada e registro curto é completado com texto
/// vazio, em vez de derrubar o arquivo como no original. Texto sem nenhuma linha e aspas abertas até o fim do texto (que
/// engoliriam os registros seguintes) são formato inválido.
public enum DelimitedParser {
    public static func parse(_ text: String, separator: Character) throws(ImportFailure) -> ImportedTable {
        var reader = FieldReader(scalars: Array(text.unicodeScalars), separator: separator.unicodeScalars.first ?? ";")
        var rows: [[String]] = []
        while let row = reader.nextRow() {
            // Linha vazia, só de espaços ou só de separadores (a área usada do Excel) não é registro.
            if row.allSatisfy(\.isEmpty) { continue }
            rows.append(row)
        }
        guard !reader.unclosedQuote, let header = rows.first else {
            throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
        }
        var columns: [String] = []
        for name in header {
            if !name.isEmpty, !ColumnNames.contains(columns, name) {
                columns.append(name)
            } else {
                columns.append(ColumnNames.next(columns))
            }
        }
        var body: [[String]] = []
        for row in rows.dropFirst() {
            while row.count > columns.count { columns.append(ColumnNames.next(columns)) }
            body.append(row)
        }
        return ImportedTable(columns: columns,
                             rows: body.map { $0 + Array(repeating: "", count: columns.count - $0.count) })
    }

}

/// `DelimitedTextStream`: lê campo a campo por escalar Unicode (CRLF é um só `Character` no Swift).
private struct FieldReader {
    let scalars: [Unicode.Scalar]
    let separator: Unicode.Scalar
    private var position = 0
    private var endOfLine = false
    /// O texto acabou dentro de um campo entre aspas.
    private(set) var unclosedQuote = false

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
                if inQuotes, !quoteClosed { unclosedQuote = true }
                return value.isEmpty && !inQuotes ? nil : String(value)
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
