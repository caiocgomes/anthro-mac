import AnthroCore
import AnthroIO
import AnthroStore
import Foundation

/// Conversões entre as estruturas de troca e os registros da Avaliação individual (design D1).
public enum ChildExchangeMapping {
    public static func exchange(child: ChildRecord, mother: ParentRecord?, father: ParentRecord?, address: AddressRecord?,
                                visits: [VisitRecord]) throws -> ExchangeChild {
        ExchangeChild(dateOfBirth: Date(timeIntervalSince1970: 0), sex: .girl)
    }

    public static func records(from child: ExchangeChild) throws -> (child: ChildRecord, mother: ParentRecord?,
                                                                     father: ParentRecord?, address: AddressRecord?,
                                                                     visits: [VisitRecord]) {
        (ChildRecord(dateOfBirth: Date(timeIntervalSince1970: 0), sex: .girl), nil, nil, nil, [])
    }
}
