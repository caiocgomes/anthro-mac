import Foundation

/// Texto de TXT, CSV e REC (design D3): BOM de UTF-8, UTF-16 LE e UTF-16 BE; sem BOM, UTF-8 estrito e, se os bytes não
/// forem UTF-8 válido, Windows-1252, a codificação de quem exporta CSV, DBF e REC no Windows. O BOM não fica no texto.
public enum TextDecoding {
    public static func decode(_ data: Data) -> String {
        let bytes = [UInt8](data)
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) {
            return String(decoding: bytes.dropFirst(3), as: UTF8.self)
        }
        if bytes.starts(with: [0xFF, 0xFE]) {
            return String(data: Data(bytes.dropFirst(2)), encoding: .utf16LittleEndian) ?? ""
        }
        if bytes.starts(with: [0xFE, 0xFF]) {
            return String(data: Data(bytes.dropFirst(2)), encoding: .utf16BigEndian) ?? ""
        }
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        return String(data: data, encoding: .windowsCP1252) ?? String(decoding: data, as: UTF8.self)
    }
}
