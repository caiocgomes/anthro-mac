import Foundation

/// TXT com tabulação e CSV com ponto e vírgula (`tsbChildrenExport_Click`).
public enum DelimitedFormat: CaseIterable, Sendable {
    case tabText, semicolonCSV

    public var separator: Character { " " }

    public var fileExtension: String { "" }
}

/// `Delimited.WriteToStream` e `WriteItem`: aspas mínimas, CRLF, UTF-8 com BOM.
public enum DelimitedWriter {
    public static func write(header: [String], rows: [[String]], separator: Character) -> String { "" }

    public static func utf8WithBOM(_ text: String) -> Data { Data() }
}
