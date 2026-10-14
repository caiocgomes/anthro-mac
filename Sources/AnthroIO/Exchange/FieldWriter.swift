import AnthroCore
import Foundation

/// Separador decimal do arquivo: vírgula em TXT e CSV, ponto no XML (design D2).
public enum DecimalStyle: Sendable {
    case comma, point
}

/// `ImportExport.WriteField`: cada valor como o original o escreve; ausente é vazio.
public enum FieldWriter {
    /// `dd-MM-yyyy HH:mm:ss` com o dia de calendário do usuário e hora 00:00:00 (design D5).
    public static func date(_ value: Date?) -> String {
        guard let value else { return "" }
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: value)
        return String(format: "%02d-%02d-%04d 00:00:00", parts.day ?? 1, parts.month ?? 1, parts.year ?? 1)
    }

    public static func boolean(_ value: Bool?) -> String {
        value.map { $0 ? "1" : "0" } ?? ""
    }

    /// Menino `1`, menina `0` (`FieldType.Gender`).
    public static func sex(_ value: Sex?) -> String {
        value.map { $0 == .boy ? "1" : "0" } ?? ""
    }

    /// Deitado `1`, em pé `0` (`FieldType.MeasureType`).
    public static func measureType(_ recumbent: Bool?) -> String {
        boolean(recumbent)
    }

    /// Sem zeros à direita (design D4), com vírgula ou ponto conforme o arquivo (D2).
    public static func decimal(_ value: Decimal?, style: DecimalStyle) -> String {
        guard let value else { return "" }
        let text = "\(value)"
        return style == .comma ? text.replacingOccurrences(of: ".", with: ",") : text
    }

    public static func integer(_ value: Int?) -> String {
        value.map(String.init) ?? ""
    }

    public static func text(_ value: String?) -> String {
        value ?? ""
    }
}
