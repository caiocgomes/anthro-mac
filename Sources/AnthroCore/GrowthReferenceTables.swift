import Foundation

/// Tabelas LMS da OMS: padrões 2006 por dia e referência 2007 por mês (design D3 e D4).
public struct GrowthReferenceTables: Sendable {
    init() {}

    public static func bundled() throws -> GrowthReferenceTables {
        GrowthReferenceTables()
    }

    public static func load(standardsCSV: [Indicator: String], referenceCSV: [Indicator: String]) throws -> GrowthReferenceTables {
        GrowthReferenceTables()
    }

    public func standardsLMS(_ indicator: Indicator, sex: Sex, ageInDays: Int) -> LMS? {
        LMS(l: 0, m: 0, s: 0)
    }

    public func referenceLMS(_ indicator: Indicator, sex: Sex, ageInMonths: Decimal) -> LMS? {
        LMS(l: 0, m: 0, s: 0)
    }

    public func rowCount(_ indicator: Indicator, range: AgeRange, sex: Sex) -> Int {
        0
    }
}
