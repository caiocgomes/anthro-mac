import Foundation

/// TXT com tabulação e CSV com ponto e vírgula (`tsbChildrenExport_Click`, `FilterIndex` 2 e 3).
public enum DelimitedFormat: CaseIterable, Sendable {
    case tabText, semicolonCSV

    public var separator: Character {
        switch self {
        case .tabText: "\t"
        case .semicolonCSV: ";"
        }
    }

    public var fileExtension: String {
        switch self {
        case .tabText: "txt"
        case .semicolonCSV: "csv"
        }
    }
}

/// `Delimited.WriteToStream` e `WriteItem`: cada linha, inclusive a última, termina em CRLF; um valor vai entre aspas,
/// com aspas internas duplicadas, só quando contém aspas, CR, LF ou o separador (design D3).
public enum DelimitedWriter {
    public static func write(header: [String], rows: [[String]], separator: Character) -> String {
        ([header] + rows).map { line in
            line.map { item(String($0), separator: separator) }.joined(separator: String(separator)) + "\r\n"
        }.joined()
    }

    /// UTF-8 com BOM, como `StreamWriter` com `Encoding.UTF8`.
    public static func utf8WithBOM(_ text: String) -> Data {
        Data([0xEF, 0xBB, 0xBF]) + Data(text.utf8)
    }

    /// A checagem é por escalar: no Swift, CRLF é um só `Character`, que não é igual a `"\r"` nem a `"\n"`.
    private static func item(_ text: String, separator: Character) -> String {
        let special = Set(["\"", "\n", "\r"].flatMap(\.unicodeScalars) + String(separator).unicodeScalars)
        guard text.unicodeScalars.contains(where: special.contains) else { return text }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
