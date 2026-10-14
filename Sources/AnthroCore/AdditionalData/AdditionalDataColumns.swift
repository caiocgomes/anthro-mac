/// Coluna de dados adicionais da tabela do inquérito (`VariableDescriptor` com a chave de `GetDataStructure`).
public struct AdditionalDataColumn: Sendable, Hashable {
    public let key: String
    public let sectionID: String
    public let variableID: String

    public init(key: String, sectionID: String, variableID: String) {
        self.key = key
        self.sectionID = sectionID
        self.variableID = variableID
    }
}

/// `AdditionalData.GetDataStructure` (design D9).
public enum AdditionalDataColumns {
    public static func structure(of definition: AdditionalData, forbiddenKeys: [String]) -> [AdditionalDataColumn] {
        []
    }
}
