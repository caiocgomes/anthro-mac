import Foundation

/// `External.ParseDBFFile` lido por bytes (design D8): número de registros no inteiro de 32 bits em 4, tamanho do
/// cabeçalho no de 16 bits em 8, um descritor de 32 bytes por campo com o nome nos 11 primeiros bytes sem NUL e a
/// largura no byte 16. Os registros começam no tamanho do cabeçalho (o original começava um byte depois dos
/// descritores e lia caracteres UTF-8, que desalinhavam com acentos em Latin-1); cada valor é decodificado como texto
/// importado e aparado. Registro marcado como apagado (`*`) é ignorado (decisão de 15/10/2026). Arquivo curto é formato
/// inválido.
public enum DBFParser {
    public static func parse(_ data: Data) throws(ImportFailure) -> ImportedTable {
        let bytes = [UInt8](data)
        guard bytes.count >= 32 else { throw invalid }
        let recordCount = Int(UInt32(bytes[4]) | UInt32(bytes[5]) << 8 | UInt32(bytes[6]) << 16 | UInt32(bytes[7]) << 24)
        let headerSize = Int(UInt16(bytes[8]) | UInt16(bytes[9]) << 8)
        let fieldCount = max((headerSize - 32) / 32, 0)
        guard bytes.count >= 32 + 32 * fieldCount, headerSize <= bytes.count else { throw invalid }
        var columns: [String] = []
        var widths: [Int] = []
        for field in 0..<fieldCount {
            let descriptor = bytes[(32 + 32 * field)..<(32 + 32 * field + 32)]
            let nameBytes = descriptor.prefix(11).filter { $0 != 0 }
            columns.append(String(decoding: nameBytes, as: UTF8.self))
            widths.append(Int(descriptor[descriptor.startIndex + 16]))
        }
        let recordSize = 1 + widths.reduce(0, +)
        var rows: [[String]] = []
        var offset = headerSize
        for _ in 0..<recordCount {
            guard offset + recordSize <= bytes.count else { throw invalid }
            let deleted = bytes[offset] == UInt8(ascii: "*")
            var cursor = offset + 1
            var row: [String] = []
            for width in widths {
                row.append(TextDecoding.decode(Data(bytes[cursor..<(cursor + width)])).trimmingCharacters(in: .whitespaces))
                cursor += width
            }
            if !deleted { rows.append(row) }
            offset += recordSize
        }
        return ImportedTable(columns: columns, rows: rows)
    }

    private static let invalid = ImportFailure.invalidStructure(ImportFailureDetail(line: nil, element: nil, attribute: nil))
}
