/// `Delimited.ParseStream` com `DelimitedTextStream.GetNextItem` (design D5 e D6).
public enum DelimitedParser {
    public static func parse(_ text: String, separator: Character) throws(ImportFailure) -> ImportedTable {
        ImportedTable(columns: [], rows: [])
    }
}
