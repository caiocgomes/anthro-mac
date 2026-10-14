/// Plausibilidade com os limites do inquérito (`Record.IsFlagged` e `Record.GetFlag`, design D4); a change
/// add-survey-analysis consome estas regras para excluir z implausíveis.
public enum SurveyPlausibility {
    /// `REF_UPPERAGELIMITMONTHS_W4A`: na referência, peso para idade com parte inteira dos meses acima deste valor nunca
    /// é implausível (constante inline de `IsFlagged`, ausente da ajuda).
    static let referenceWeightForAgeUpperMonths = 108

    /// z indefinido ou fora dos limites das opções para a faixa; faixa desconhecida ou fora dos limites é sempre
    /// implausível.
    public static func isFlagged(_ indicator: Indicator, result: AnthropometricResult, options: SurveyOptions) -> Bool {
        if result.ageRange == .reference, indicator == .weightForAge, let months = result.ageInMonths,
           AgeMath.truncated(months) > referenceWeightForAgeUpperMonths {
            return false
        }
        guard let bounds = options.zBounds(indicator, range: result.ageRange),
              let z = result.score(indicator).zScore else { return true }
        return z < bounds.min || z > bounds.max
    }

    /// Ordem do original: estatura e peso, peso, estatura, IMC, nenhuma.
    public static func flag(result: AnthropometricResult, options: SurveyOptions) -> PlausibilityFlag {
        let weight = isFlagged(.weightForAge, result: result, options: options)
        let length = isFlagged(.lengthOrHeightForAge, result: result, options: options)
        if weight && length { return .weightAndLengthOrHeightForAge }
        if weight { return .weightForAge }
        if length { return .lengthOrHeightForAge }
        return isFlagged(.bmiForAge, result: result, options: options) ? .bmiForAge : .none
    }
}
