import Foundation

/// Port de `AnthroComputation.GetAnthroResult` (design D1 a D3).
public struct AnthroEngine: Sendable {
    let tables: GrowthReferenceTables

    public init(tables: GrowthReferenceTables) {
        self.tables = tables
    }

    public static func shared() throws -> AnthroEngine {
        AnthroEngine(tables: try GrowthReferenceTables.bundled())
    }

    public func result(
        ageInDays: Int?, ageInMonths: Decimal?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?,
        measuredRecumbent: Bool, hasOedema: Bool
    ) -> AnthropometricResult {
        let zero = IndicatorScore(zScore: 0, percentile: 0)
        return AnthropometricResult(
            sex: nil, ageInDays: 0, ageInMonths: 0, ageRange: .unknown, weight: 0, lengthOrHeight: 0,
            adjustedLengthOrHeight: 0, isLength: false, weightForAge: zero, lengthOrHeightForAge: zero, bmiForAge: zero
        )
    }

    public func result(
        dateOfBirth: Date?, dateOfVisit: Date?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?,
        measuredRecumbent: Bool, hasOedema: Bool
    ) throws -> AnthropometricResult {
        result(ageInDays: 0, ageInMonths: 0, sex: sex, weight: weight, lengthOrHeight: lengthOrHeight,
               measuredRecumbent: measuredRecumbent, hasOedema: hasOedema)
    }
}
