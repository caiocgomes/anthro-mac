import AnthroCore
import Foundation

/// Registro de entrada da análise (design D1): idade, sexo, cluster, fator, edema, medidas brutas, z arredondados por
/// indicador e os indicadores marcados como implausíveis pelos limites do inquérito.
public struct AnalysisRecord: Sendable, Equatable {
    public var ageInMonths: Decimal?
    public var sex: Sex?
    public var cluster: Int?
    public var weightingFactor: Decimal
    public var hasOedema: Bool?
    public var weight: Decimal?
    public var height: Decimal?
    public var zScores: [Indicator: Decimal]
    public var flagged: Set<Indicator>

    public init(ageInMonths: Decimal?, sex: Sex?, cluster: Int? = nil, weightingFactor: Decimal = 1, hasOedema: Bool? = nil,
                weight: Decimal? = nil, height: Decimal? = nil, zScores: [Indicator: Decimal] = [:],
                flagged: Set<Indicator> = []) {
        self.ageInMonths = ageInMonths
        self.sex = sex
        self.cluster = cluster
        self.weightingFactor = weightingFactor
        self.hasOedema = hasOedema
        self.weight = weight
        self.height = height
        self.zScores = zScores
        self.flagged = flagged
    }
}
