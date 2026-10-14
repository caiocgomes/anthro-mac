import AnthroCore

/// `AdditionalData.GetVariableValueAsString` com o estilo decimal do arquivo: texto como está, número sem zeros à
/// direita, data `dd-MM-yyyy HH:mm:ss`; variável ausente ou sem valor fica vazia.
public enum AdditionalValueText {
    public static func text(_ variable: AdditionalDataVariable?, style: DecimalStyle) -> String {
        switch variable?.kind {
        case .text(let value): value ?? ""
        case .number(let value, _, _): FieldWriter.decimal(value, style: style)
        case .date(let value): FieldWriter.date(value)
        case nil: ""
        }
    }
}
