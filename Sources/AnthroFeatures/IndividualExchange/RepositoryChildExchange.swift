import AnthroCore
import AnthroIO
import AnthroStore

/// Adaptador entre os repositórios da Avaliação individual e as estruturas de troca (design D1 e D10).
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

    /// Crianças na ordem pedida, com pais, endereço e visitas; resultados calculados só quando pedidos.
    public func exchangeChildren(ids: [Int64], includeResults: Bool) throws -> [ExchangeChild] {
        try ids.map { id in
            guard let child = try children.child(id: id) else { throw StoreError.recordNotFound(table: "children", id: id) }
            var exchanged = try ChildExchangeMapping.exchange(
                child: child,
                mother: try child.motherID.flatMap { try parents.parent(kind: .mother, id: $0) },
                father: try child.fatherID.flatMap { try parents.parent(kind: .father, id: $0) },
                address: try child.addressID.flatMap { try addresses.address(id: $0) },
                visits: try visits.visits(childID: id))
            if includeResults {
                for index in exchanged.visits.indices {
                    exchanged.visits[index].results = ExchangeResultsCalculator.results(
                        engine: engine, sex: exchanged.sex, dateOfBirth: exchanged.dateOfBirth, visit: exchanged.visits[index])
                }
            }
            return exchanged
        }
    }

    /// O modelo da Avaliação individual, que define as colunas de dados adicionais da exportação (D14).
    public func additionalDataDefinition() throws -> AdditionalData {
        try templates.individualAssessmentTemplate()
    }

    /// Mães, pais, endereços, crianças e visitas numa única transação, preservando o `DisplayID` do arquivo (D10).
    public func insertAll(_ children: [ExchangeChild]) throws -> Int {
        try database.transaction {
            for child in children {
                let records = try ChildExchangeMapping.records(from: child)
                var record = records.child
                record.motherID = try records.mother.map { try parents.save($0).id } ?? nil
                record.fatherID = try records.father.map { try parents.save($0).id } ?? nil
                record.addressID = try records.address.map { try addresses.save($0).id } ?? nil
                try self.children.save(record, visits: records.visits)
            }
            return children.count
        }
    }
}
