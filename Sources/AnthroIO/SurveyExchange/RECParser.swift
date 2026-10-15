/// `External.ParseRECFile` do Epi Info (design D7).
public enum RECParser {
    public static func parse(_ text: String) throws(ImportFailure) -> ImportedTable {
        ImportedTable(columns: [], rows: [])
    }
}
