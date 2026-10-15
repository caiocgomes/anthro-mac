/// `External.ParseRECFile` do Epi Info (design D7): o primeiro token da primeira linha é o número de campos; cada
/// descritor traz o nome no token 1 e a largura no token 8, e largura 0 é ignorada; o registro tem largura fixa, e uma
/// linha de exatamente 79 caracteres perde o último (marcador de continuação) e continua na seguinte; linha com menos
/// de 2 caracteres não gera registro; valores sem espaço e NUL nas pontas. Qualquer falha é formato inválido.
public enum RECParser {
    public static func parse(_ text: String) throws(ImportFailure) -> ImportedTable {
        var lines = text.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })
            .map(String.init)
        if lines.last == "" { lines.removeLast() }
        var index = 0
        func nextLine() throws(ImportFailure) -> String {
            guard index < lines.count else { throw invalid }
            defer { index += 1 }
            return lines[index]
        }
        guard let count = Int(try nextLine().split(separator: " ").first ?? "") else { throw invalid }
        var columns: [String] = []
        var widths: [Int] = []
        for _ in 0..<max(count, 0) {
            let tokens = try nextLine().split(separator: " ").map(String.init)
            guard tokens.count >= 8, let width = Int(tokens[7]) else { throw invalid }
            if width != 0 {
                columns.append(tokens[0])
                widths.append(width)
            }
        }
        let total = widths.reduce(0, +)
        var rows: [[String]] = []
        while index < lines.count {
            var record = ""
            repeat {
                let line = try nextLine()
                guard line.count == 79 else {
                    record += line
                    break
                }
                record += line.dropLast()
            } while record.count < total && index < lines.count
            guard record.count >= 2 else { continue }
            guard record.count >= total else { throw invalid }
            var start = record.startIndex
            var row: [String] = []
            for width in widths {
                let end = record.index(start, offsetBy: width)
                row.append(String(record[start..<end]).trimmingCharacters(in: [" ", "\u{0}"]))
                start = end
            }
            rows.append(row)
        }
        return ImportedTable(columns: columns, rows: rows)
    }

    private static let invalid = ImportFailure.invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
}
