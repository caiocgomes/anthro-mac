import AnthroAnalysis
import AnthroCore
import Foundation

/// `Decimal` exato a partir do texto (literais de ponto flutuante passariam por `Double`).
func d(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

/// Registros de análise montados à mão (design D1).
enum AnalysisFixtures {
    /// Os z dos cenários de dez registros.
    static let tenZ = ["-3.5", "-2.5", "-2.1", "-1.0", "0.0", "0.5", "1.2", "2.2", "3.1", "0.0"].map(d)

    /// Os doze z de densidade.
    static let twelveZ = ["-2", "-1.5", "-1", "-0.5", "0", "0", "0.5", "1", "1.5", "2", "-0.25", "0.25"].map(d)

    /// Registro com o mesmo z em todos os indicadores pedidos.
    static func record(age: Decimal? = 96, z: Decimal?, indicators: [Indicator] = Indicator.allCases, sex: Sex? = .boy,
                       cluster: Int? = nil, factor: Decimal = 1, oedema: Bool? = nil, flagged: Set<Indicator> = [],
                       weight: Decimal? = nil, height: Decimal? = nil) -> AnalysisRecord {
        var scores: [Indicator: Decimal] = [:]
        if let z { for indicator in indicators { scores[indicator] = z } }
        return AnalysisRecord(ageInMonths: age, sex: sex, cluster: cluster, weightingFactor: factor, hasOedema: oedema,
                              weight: weight, height: height, zScores: scores, flagged: flagged)
    }

    /// Dez registros de 96 meses, fator 1, sem edema, com os z de `tenZ` nos três indicadores.
    static func tenRecords() -> [AnalysisRecord] {
        tenZ.enumerated().map { record(z: $0.element, sex: $0.offset.isMultiple(of: 2) ? .boy : .girl) }
    }

    /// Quatro clusters de cinco registros de 96 meses, com 1, 2, 0 e 1 registros de z -2.5 e os demais com z 0.
    static func fourClusters() -> [AnalysisRecord] {
        let cases = [1: 1, 2: 2, 3: 0, 4: 1]
        return (1...4).flatMap { cluster in
            (0..<5).map { index in record(z: index < cases[cluster]! ? d("-2.5") : 0, cluster: cluster) }
        }
    }

    /// `ComputePrevalences` como a linha de total do relatório: população inteira, sem análise por cluster.
    static func compute(_ records: [AnalysisRecord], _ indicator: Indicator, options: SurveyOptions = .default,
                        type: AnalysisType = .standard, improved: Bool = false) throws -> PrevalenceResult {
        try PrevalenceCalculator.compute(records, indicator: indicator, options: options, analysisType: type, isTotal: true,
                                         byCluster: false, improvedClusterAnalysis: improved)
    }

    static func options(boundaries: [Int]) -> SurveyOptions {
        var options = SurveyOptions.default
        options.ageGroupBoundaries = boundaries
        return options
    }
}
