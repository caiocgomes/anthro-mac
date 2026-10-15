import AnthroAnalysis
import AnthroCore
import Foundation

/// Monta a entrada da análise a partir dos registros da change 5 (design D1): idade informada ou das datas, z do
/// resultado (já com 2 casas), medidas brutas e, em `flagged`, os indicadores que `SurveyPlausibility` marca com as
/// opções do inquérito, sem limites próprios.
public enum SurveyAnalysisInput {
    public static func records(from surveyRecords: [SurveyRecord], options: SurveyOptions, engine: AnthroEngine) -> [AnalysisRecord] {
        surveyRecords.map { record in
            let result = SurveyRecordEvaluation.result(record, engine: engine)
            var scores: [Indicator: Decimal] = [:]
            for indicator in Indicator.allCases {
                if let z = result.score(indicator).zScore { scores[indicator] = z }
            }
            let flagged = Set(Indicator.allCases.filter { SurveyPlausibility.isFlagged($0, result: result, options: options) })
            return AnalysisRecord(ageInMonths: SurveyRecordEvaluation.ageInMonths(record), sex: record.sex, cluster: record.cluster,
                                  weightingFactor: record.weightingFactor, hasOedema: record.hasOedema, weight: record.weight,
                                  height: record.lengthOrHeight, zScores: scores, flagged: flagged)
        }
    }
}
