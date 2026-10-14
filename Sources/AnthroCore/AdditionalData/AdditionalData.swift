import Foundation

/// Variável de dados adicionais (`Text`, `Num` e `Date` do original): identificador, descrição e valor do tipo.
public struct AdditionalDataVariable: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case text(String?)
        case number(value: Decimal?, minimum: Decimal?, maximum: Decimal?)
        case date(Date?)
    }

    public var identifier: String
    public var description: String?
    public var kind: Kind

    public init(identifier: String, description: String? = nil, kind: Kind) {
        self.identifier = identifier
        self.description = description
        self.kind = kind
    }
}

/// Seção (`Section` do original) com as suas variáveis em ordem.
public struct AdditionalDataSection: Sendable, Equatable {
    public var identifier: String
    public var description: String?
    public var variables: [AdditionalDataVariable]

    public init(identifier: String, description: String? = nil, variables: [AdditionalDataVariable] = []) {
        self.identifier = identifier
        self.description = description
        self.variables = variables
    }

    public func variable(_ identifier: String) -> AdditionalDataVariable? {
        nil
    }
}

/// Dados adicionais (`AdditionalData` do original): valor puro, copiado por atribuição (design D1).
public struct AdditionalData: Sendable, Equatable {
    public var sections: [AdditionalDataSection]

    public init(sections: [AdditionalDataSection] = []) {
        self.sections = sections
    }

    public func section(_ identifier: String) -> AdditionalDataSection? {
        nil
    }

    public func variable(section: String, variable: String) -> AdditionalDataVariable? {
        nil
    }
}
