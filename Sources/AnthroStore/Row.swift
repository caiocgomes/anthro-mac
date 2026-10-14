/// Linha devolvida por `AnthroDatabase.query`; coluna ausente devolve `.null`.
public struct Row: Sendable {
    let values: [String: SQLValue]

    init(values: [String: SQLValue]) {
        self.values = values
    }

    public subscript(_ column: String) -> SQLValue {
        .null
    }
}
