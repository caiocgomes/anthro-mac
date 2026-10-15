import Foundation

/// Arquivo DBF (dBase III) montado em memória: cabeçalho de 32 bytes, um descritor de 32 bytes por campo, terminador
/// 0x0D, e registros com o marcador de apagado (`" "` ou `"*"`) seguido dos valores com a largura do campo.
enum DBFBuilder {
    struct Field {
        let name: String
        let width: Int
    }

    static func data(fields: [Field], records: [(deleted: Bool, values: [String])], declaredRecords: Int? = nil) -> Data {
        let headerSize = 32 + 32 * fields.count + 1
        let recordSize = 1 + fields.reduce(0) { $0 + $1.width }
        var bytes = [UInt8](repeating: 0, count: 32)
        bytes[0] = 0x03
        put32(&bytes, 4, UInt32(declaredRecords ?? records.count))
        put16(&bytes, 8, UInt16(headerSize))
        put16(&bytes, 10, UInt16(recordSize))
        for field in fields {
            var descriptor = [UInt8](repeating: 0, count: 32)
            for (index, byte) in Array(field.name.utf8.prefix(11)).enumerated() { descriptor[index] = byte }
            descriptor[11] = UInt8(ascii: "C")
            descriptor[16] = UInt8(field.width)
            bytes += descriptor
        }
        bytes.append(0x0D)
        for record in records {
            bytes.append(UInt8(ascii: record.deleted ? "*" : " "))
            for (field, value) in zip(fields, record.values) {
                var cell = Array(value.utf8.prefix(field.width))
                cell += [UInt8](repeating: 0x20, count: field.width - cell.count)
                bytes += cell
            }
        }
        bytes.append(0x1A)
        return Data(bytes)
    }

    private static func put32(_ bytes: inout [UInt8], _ offset: Int, _ value: UInt32) {
        for i in 0..<4 { bytes[offset + i] = UInt8((value >> (8 * UInt32(i))) & 0xFF) }
    }

    private static func put16(_ bytes: inout [UInt8], _ offset: Int, _ value: UInt16) {
        for i in 0..<2 { bytes[offset + i] = UInt8((value >> (8 * UInt16(i))) & 0xFF) }
    }
}
