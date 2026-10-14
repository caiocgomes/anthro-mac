import Foundation

/// Tabelas LMS da OMS: padrões 2006 por dia e referência 2007 por mês (design D3 e D4).
public struct GrowthReferenceTables: Sendable {
    /// Uma tabela contígua: `rows[i]` é a linha da idade `firstAge + i`.
    struct Table: Sendable {
        let firstAge: Int
        let rows: [LMS]

        func row(_ age: Int) -> LMS? {
            let index = age - firstAge
            return rows.indices.contains(index) ? rows[index] : nil
        }
    }

    struct Key: Hashable, Sendable {
        let standards: Bool
        let indicator: Indicator
        let sex: Sex
    }

    /// Intervalos declarados de cada tabela (idades inclusivas).
    static func declaredAges(standards: Bool, indicator: Indicator) -> ClosedRange<Int> {
        if standards { return 0...1856 }
        return indicator == .weightForAge ? 60...121 : 60...229
    }

    static func resourceName(standards: Bool, indicator: Indicator) -> String {
        let suffix = switch indicator {
        case .weightForAge: "wfa"
        case .lengthOrHeightForAge: "lhfa"
        case .bmiForAge: "bfa"
        }
        return (standards ? "std-" : "ref-") + suffix
    }

    let tables: [Key: Table]

    init(tables: [Key: Table] = [:]) {
        self.tables = tables
    }

    private static let cachedBundled: Result<GrowthReferenceTables, Error> = Result {
        guard let directory = AnthroCoreResources.whoDirectory else {
            throw ReferenceDataError.missingResource("who")
        }
        func read(_ standards: Bool) throws -> [Indicator: String] {
            var texts: [Indicator: String] = [:]
            for indicator in Indicator.allCases {
                let name = resourceName(standards: standards, indicator: indicator)
                let url = directory.appendingPathComponent("\(name).csv")
                guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                    throw ReferenceDataError.missingResource(name)
                }
                texts[indicator] = text
            }
            return texts
        }
        return try load(standardsCSV: read(true), referenceCSV: read(false))
    }

    /// Tabelas embutidas no bundle do `AnthroCore`, carregadas e validadas uma única vez.
    public static func bundled() throws -> GrowthReferenceTables {
        try cachedBundled.get()
    }

    /// Carrega CSVs `sex,age,l,m,s` (sex 1 = menino, 2 = menina) e exige idades contíguas nos intervalos declarados.
    public static func load(standardsCSV: [Indicator: String], referenceCSV: [Indicator: String]) throws -> GrowthReferenceTables {
        var tables: [Key: Table] = [:]
        for (standards, sources) in [(true, standardsCSV), (false, referenceCSV)] {
            for indicator in Indicator.allCases {
                let name = resourceName(standards: standards, indicator: indicator)
                guard let text = sources[indicator] else { throw ReferenceDataError.missingResource(name) }
                let parsed = try parse(text, file: name)
                let ages = declaredAges(standards: standards, indicator: indicator)
                for sex in [Sex.boy, .girl] {
                    let bySex = parsed[sex] ?? [:]
                    var rows: [LMS] = []
                    rows.reserveCapacity(ages.count)
                    for age in ages {
                        guard let lms = bySex[age] else {
                            throw ReferenceDataError.gap(indicator: indicator, sex: sex, age: age)
                        }
                        rows.append(lms)
                    }
                    tables[Key(standards: standards, indicator: indicator, sex: sex)] = Table(firstAge: ages.lowerBound, rows: rows)
                }
            }
        }
        return GrowthReferenceTables(tables: tables)
    }

    private static func parse(_ text: String, file: String) throws -> [Sex: [Int: LMS]] {
        let posix = Locale(identifier: "en_US_POSIX")
        var result: [Sex: [Int: LMS]] = [:]
        for (offset, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineNumber = offset + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if lineNumber == 1 || line.isEmpty { continue }
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 5,
                  let sex = fields[0] == "1" ? Sex.boy : (fields[0] == "2" ? Sex.girl : nil),
                  let age = Int(fields[1]),
                  let l = Decimal(string: fields[2], locale: posix),
                  let m = Decimal(string: fields[3], locale: posix),
                  let s = Decimal(string: fields[4], locale: posix),
                  fields[2...4].allSatisfy({ $0.range(of: #"^-?[0-9]+(\.[0-9]+)?$"#, options: .regularExpression) != nil })
            else {
                throw ReferenceDataError.malformedRow(file: file, line: lineNumber)
            }
            result[sex, default: [:]][age] = LMS(l: l, m: m, s: s)
        }
        return result
    }

    public func standardsLMS(_ indicator: Indicator, sex: Sex, ageInDays: Int) -> LMS? {
        tables[Key(standards: true, indicator: indicator, sex: sex)]?.row(ageInDays)
    }

    public func referenceLMS(_ indicator: Indicator, sex: Sex, ageInMonths: Decimal) -> LMS? {
        guard let table = tables[Key(standards: false, indicator: indicator, sex: sex)],
              let rounded = ClinicalRounding.round(ageInMonths, places: 0),
              rounded == ageInMonths else { return nil }
        return table.row(NSDecimalNumber(decimal: rounded).intValue)
    }

    public func rowCount(_ indicator: Indicator, range: AgeRange, sex: Sex) -> Int {
        switch range {
        case .standards: tables[Key(standards: true, indicator: indicator, sex: sex)]?.rows.count ?? 0
        case .reference: tables[Key(standards: false, indicator: indicator, sex: sex)]?.rows.count ?? 0
        case .unknown, .offLimits: 0
        }
    }
}
