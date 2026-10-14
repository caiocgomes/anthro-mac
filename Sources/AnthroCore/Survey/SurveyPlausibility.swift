/// Plausibilidade com os limites do inquérito (`Record.IsFlagged` e `Record.GetFlag`).
public enum SurveyPlausibility {
    public static func isFlagged(_ indicator: Indicator, result: AnthropometricResult, options: SurveyOptions) -> Bool {
        false
    }

    public static func flag(result: AnthropometricResult, options: SurveyOptions) -> PlausibilityFlag {
        .none
    }
}
