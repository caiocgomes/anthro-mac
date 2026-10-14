import Foundation

/// Port de `AnthroComputation.GetAnthroResult` e dos `Compute*4Age` (design D1 a D3).
public struct AnthroEngine: Sendable {
    let tables: GrowthReferenceTables

    private static let minimumWeight = Decimal(string: "0.9")!

    public init(tables: GrowthReferenceTables) {
        self.tables = tables
    }

    /// Motor com as tabelas embutidas no bundle.
    public static func shared() throws -> AnthroEngine {
        AnthroEngine(tables: try GrowthReferenceTables.bundled())
    }

    public func result(
        ageInDays: Int?, ageInMonths: Decimal?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?,
        measuredRecumbent: Bool, hasOedema: Bool
    ) -> AnthropometricResult {
        let weight = ClinicalRounding.round(weight, places: 2)
        let measure = ClinicalRounding.round(lengthOrHeight, places: 2)
        let undefined = IndicatorScore(zScore: nil, percentile: nil)

        func empty(days: Int?, months: Decimal?, range: AgeRange, adjusted: Decimal?, isLength: Bool) -> AnthropometricResult {
            AnthropometricResult(
                sex: sex, ageInDays: days, ageInMonths: months, ageRange: range, weight: weight,
                lengthOrHeight: measure, adjustedLengthOrHeight: adjusted, isLength: isLength,
                weightForAge: undefined, lengthOrHeightForAge: undefined, bmiForAge: undefined
            )
        }

        guard ageInDays != nil || ageInMonths != nil else {
            return empty(days: nil, months: nil, range: .unknown, adjusted: nil, isLength: measuredRecumbent)
        }
        let days = ageInDays ?? AgeMath.monthsToDays(ageInMonths!)
        var months = ageInMonths ?? AgeMath.daysToMonths(ageInDays!)
        let range = AgeMath.ageRange(days: days, months: months)
        if range == .offLimits {
            return empty(days: days, months: months, range: range, adjusted: nil, isLength: measuredRecumbent)
        }
        if range == .reference && months < 11 {
            months = 11  // como GetAnthroResult; só alcançável com dias e meses informados juntos e incoerentes
        }

        let adjusted: Decimal?
        let isLength: Bool
        if range == .standards, let measure {
            (adjusted, isLength) = Anthropometry.adjustedLengthOrHeight(ageInDays: days, value: measure, measuredRecumbent: measuredRecumbent)
        } else {
            (adjusted, isLength) = (measure, measuredRecumbent)
        }

        guard let sex else {
            return empty(days: days, months: months, range: range, adjusted: adjusted, isLength: isLength)
        }

        func lms(_ indicator: Indicator) -> LMS? {
            range == .standards
                ? tables.standardsLMS(indicator, sex: sex, ageInDays: days)
                : tables.referenceLMS(indicator, sex: sex, ageInMonths: months)
        }

        func score(_ indicator: Indicator, measurement: Decimal?, restricted: Bool) -> IndicatorScore {
            guard let measurement, let row = lms(indicator),
                  let z = ZScore.lms(measurement, row, restricted: restricted) else { return undefined }
            return IndicatorScore(
                zScore: ClinicalRounding.round(z, places: 2),
                percentile: ClinicalRounding.round(ZScore.centile(z), places: 1)
            )
        }

        // ComputeWeight4Age: edema ou peso abaixo de 0,9 kg tornam o indicador indefinido.
        let weightForAge = (hasOedema || (weight ?? 0) < Self.minimumWeight)
            ? undefined
            : score(.weightForAge, measurement: weight, restricted: true)

        // ComputeLengthOrHeight4Age: medida menor que 1 é indefinida; sem ajuste além de 3 DP.
        let lengthOrHeightForAge = (adjusted ?? 0) < 1
            ? undefined
            : score(.lengthOrHeightForAge, measurement: adjusted, restricted: false)

        // ComputeBMI4Age: edema, peso ou medida não positivos tornam o indicador indefinido.
        var bmiForAge = undefined
        if !hasOedema, let weight, let adjusted, weight > 0, adjusted > 0 {
            bmiForAge = score(.bmiForAge, measurement: Anthropometry.exactBMI(weight: weight, lengthOrHeight: adjusted), restricted: true)
        }

        return AnthropometricResult(
            sex: sex, ageInDays: days, ageInMonths: months, ageRange: range, weight: weight,
            lengthOrHeight: measure, adjustedLengthOrHeight: adjusted, isLength: isLength,
            weightForAge: weightForAge, lengthOrHeightForAge: lengthOrHeightForAge, bmiForAge: bmiForAge
        )
    }

    /// Mesma regra a partir das datas; nascimento depois da visita lança `AnthroError.birthAfterVisit`.
    public func result(
        dateOfBirth: Date?, dateOfVisit: Date?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?,
        measuredRecumbent: Bool, hasOedema: Bool
    ) throws -> AnthropometricResult {
        var days: Int?
        var months: Decimal?
        if let dateOfBirth, let dateOfVisit {
            let ageInDays = try AgeMath.ageInDays(birth: dateOfBirth, visit: dateOfVisit)
            days = ageInDays
            months = AgeMath.daysToMonths(ageInDays)
        }
        return result(ageInDays: days, ageInMonths: months, sex: sex, weight: weight, lengthOrHeight: lengthOrHeight,
                      measuredRecumbent: measuredRecumbent, hasOedema: hasOedema)
    }
}
