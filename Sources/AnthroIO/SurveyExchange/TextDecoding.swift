import Foundation

/// Texto de TXT, CSV e REC: BOM de UTF-8 e UTF-16, UTF-8 estrito e Windows-1252 como segunda opção (design D3).
public enum TextDecoding {
    public static func decode(_ data: Data) -> String { "" }
}
