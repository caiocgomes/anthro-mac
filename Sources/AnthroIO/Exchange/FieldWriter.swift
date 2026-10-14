import AnthroCore
import Foundation

/// Separador decimal do arquivo: vírgula em TXT e CSV, ponto no XML (design D2).
public enum DecimalStyle: Sendable {
    case comma, point
}

/// `ImportExport.WriteField`: cada valor como o original o escreve.
public enum FieldWriter {
    public static func date(_ value: Date?) -> String { "" }
    public static func boolean(_ value: Bool?) -> String { "" }
    public static func sex(_ value: Sex?) -> String { "" }
    public static func measureType(_ recumbent: Bool?) -> String { "" }
    public static func decimal(_ value: Decimal?, style: DecimalStyle) -> String { "" }
    public static func integer(_ value: Int?) -> String { "" }
    public static func text(_ value: String?) -> String { "" }
}
