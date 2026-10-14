import AnthroCore
import AnthroIO
import AnthroStore

/// Adaptador entre os repositórios da Avaliação individual e as estruturas de troca.
public struct RepositoryChildExchange: ChildExchangeSource, ChildImportSink {
    private let database: AnthroDatabase
    private let children: ChildRepository
    private let visits: VisitRepository
    private let parents: ParentRepository
    private let addresses: AddressRepository
    private let templates: AdditionalDataTemplateRepository
    private let engine: AnthroEngine

    public init(database: AnthroDatabase, children: ChildRepository, visits: VisitRepository, parents: ParentRepository,
                addresses: AddressRepository, templates: AdditionalDataTemplateRepository, engine: AnthroEngine) {
        self.database = database
        self.children = children
        self.visits = visits
        self.parents = parents
        self.addresses = addresses
        self.templates = templates
        self.engine = engine
    }

    public func exchangeChildren(ids: [Int64], includeResults: Bool) throws -> [ExchangeChild] { [] }

    public func additionalDataDefinition() throws -> AdditionalData { AdditionalData() }

    public func insertAll(_ children: [ExchangeChild]) throws -> Int { 0 }
}
