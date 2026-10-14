/// Campo com erro numa linha importada (`ImportFieldError` do original).
public struct ImportFieldError: Equatable, Sendable {
    public let line: Int
    public let field: String

    public init(line: Int, field: String) {
        self.line = line
        self.field = field
    }
}

/// Onde a leitura falhou: só para a mensagem, o original não informa (design D6).
public struct ImportFailureDetail: Equatable, Sendable {
    public let line: Int?
    public let element: String?
    public let attribute: String?

    public init(line: Int?, element: String?, attribute: String?) {
        self.line = line
        self.element = element
        self.attribute = attribute
    }
}

/// `ImportFailureType` do original.
public enum ImportFailure: Error, Equatable, Sendable {
    case invalidStructure(ImportFailureDetail?)
    case missingField([ImportFieldError])
    case invalidFieldValue([ImportFieldError])
}
