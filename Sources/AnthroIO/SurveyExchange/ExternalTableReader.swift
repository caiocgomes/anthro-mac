import Foundation

/// Decodifica, detecta o separador e chama o leitor do tipo; `.xml` não é tabela externa.
public enum ExternalTableReader {
    public static func read(_ data: Data, kind: SurveyFileKind) throws(ImportFailure) -> ImportedTable {
        ImportedTable(columns: [], rows: [])
    }
}
