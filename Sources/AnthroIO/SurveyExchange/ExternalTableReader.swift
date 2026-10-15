import Foundation

/// Decodifica o texto, detecta o separador na primeira linha e chama o leitor do tipo; `.xml` não é tabela externa.
public enum ExternalTableReader {
    public static func read(_ data: Data, kind: SurveyFileKind) throws(ImportFailure) -> ImportedTable {
        switch kind {
        case .delimited(let fallback):
            let text = TextDecoding.decode(data)
            // A primeira linha com conteúdo, a mesma que o leitor toma como cabeçalho: linhas só de espaços,
            // separadores ou aspas vazias ele descarta.
            let firstLine = text.split(whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })
                .first { $0.contains { !$0.isWhitespace && !"\";,".contains($0) } } ?? ""
            return try DelimitedParser.parse(text, separator: SeparatorDetector.detect(firstLine: String(firstLine),
                                                                                       fallback: fallback))
        case .rec:
            return try withColumns(RECParser.parse(TextDecoding.decode(data)))
        case .dbf:
            return try withColumns(DBFParser.parse(data))
        case .xml:
            throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
        }
    }

    /// Tabela sem colunas abriria a folha de associação vazia, sem como confirmar.
    private static func withColumns(_ table: ImportedTable) throws(ImportFailure) -> ImportedTable {
        guard !table.columns.isEmpty else {
            throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
        }
        return table
    }
}
