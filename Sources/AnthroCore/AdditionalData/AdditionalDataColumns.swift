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
    /// Uma coluna por variável, na ordem das seções; chave repetida ou proibida recebe " 2", " 3" e assim por diante.
    public static func structure(of definition: AdditionalData, forbiddenKeys: [String]) -> [AdditionalDataColumn] {
        let forbidden = Set(forbiddenKeys)
        var used: Set<String> = []
        var columns: [AdditionalDataColumn] = []
        for section in definition.sections {
            for variable in section.variables {
                var key = variable.identifier
                var suffix = 2
                while used.contains(key) || forbidden.contains(key) {
                    key = "\(variable.identifier) \(suffix)"
                    suffix += 1
                }
                used.insert(key)
                columns.append(AdditionalDataColumn(key: key, sectionID: section.identifier, variableID: variable.identifier))
            }
        }
        return columns
    }
}
