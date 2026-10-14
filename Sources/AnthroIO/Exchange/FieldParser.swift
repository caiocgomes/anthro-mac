import AnthroCore
import Foundation

public enum FieldParseError: Error, Equatable, Sendable {
    case missing, invalid, outOfRange
}

/// `ImportExport.ParseField`: leitura de cada atributo com nulos, limites e truncamento.
public enum FieldParser {
    public static func boolean(_ text: String?, nullable: Bool) throws(FieldParseError) -> Bool? { nil }

    public static func sex(_ text: String?) throws(FieldParseError) -> Sex { .girl }

    public static func measureType(_ text: String?) throws(FieldParseError) -> Bool { false }

    public static func date(_ text: String?, nullable: Bool, notBefore: Date? = nil,
                            notAfter: Date? = nil) throws(FieldParseError) -> Date? { nil }

    public static func decimal(_ text: String?, nullable: Bool, unsigned: Bool, min: Decimal? = nil, max: Decimal? = nil,
                               truncateToPlaces: Int? = 2) throws(FieldParseError) -> Decimal? { nil }

    public static func unsignedInteger(_ text: String?, nullable: Bool, min: Int? = nil,
                                       max: Int? = nil) throws(FieldParseError) -> Int? { nil }

    public static func text(_ text: String?, nullable: Bool, maxLength: Int? = nil) throws(FieldParseError) -> String? {
        nil
    }

    public static func truncate(_ value: Decimal, places: Int) -> Decimal { value }
}
