import Foundation

/// Decodifica o texto, detecta o separador na primeira linha e chama o leitor do tipo; `.xml` não é tabela externa.
public enum ExternalTableReader {
    public static func read(_ data: Data, kind: SurveyFileKind) throws(ImportFailure) -> ImportedTable {
        switch kind {
        case .delimited(let fallback):
            let text = TextDecoding.decode(data)
            // A primeira linha com conteúdo, a mesma que o leitor toma como cabeçalho.
            let firstLine = text.split(whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })
                .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
            return try DelimitedParser.parse(text, separator: SeparatorDetector.detect(firstLine: String(firstLine),
                                                                                       fallback: fallback))
        case .rec:
            return try RECParser.parse(TextDecoding.decode(data))
        case .dbf:
            return try DBFParser.parse(data)
        case .xml:
            throw .invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
        }
    }
}
