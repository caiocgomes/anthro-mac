import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

@MainActor
@Suite("individual-data-exchange: mapeamento e adaptador (unitários)")
struct ChildExchangeMappingUnitTests {
    private let school = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola", variables: [
        AdditionalDataVariable(identifier: "Série", kind: .text("3º ano"))])])

    private var complete: ExchangeChild {
        ExchangeChild(displayID: 5, firstName: "Ana", lastName: "Silva", dateOfBirth: day("2016-03-15"), dateOfBirthIsApprox: true,
                      sex: .girl, notes: "nota",
                      mother: ExchangePerson(firstName: "Maria", height: num("162.5"), dateOfBirth: day("1985-05-02")),
                      father: ExchangePerson(lastName: "Silva", weight: num("80")),
                      address: ExchangeAddress(streetInfo: "Rua A", place: "São Paulo", zip: "04023", email: "a@b.org"),
                      visits: [ExchangeVisit(date: day("2021-04-01"), weight: num("18.4"), height: num("110"), isRecumbent: false,
                                             hasOedema: true, notes: "manhã", additionalData: school),
                               ExchangeVisit(date: day("2021-10-01"), weight: num("19"))])
    }

    @Test func recordsAndBackKeepEveryExchangedField() throws {
        let records = try ChildExchangeMapping.records(from: complete)
        #expect(records.child.displayID == 5)
        #expect(records.mother?.kind == .mother)
        #expect(records.father?.kind == .father)
        #expect(records.visits.first?.lengthOrHeight == num("110"))
        #expect(records.visits.first?.additionalDataXML == AdditionalDataXML.encode(school))
        #expect(records.visits.last?.additionalDataXML == nil)
        let back = try ChildExchangeMapping.exchange(child: records.child, mother: records.mother, father: records.father,
                                                     address: records.address, visits: records.visits)
        #expect(back == complete)
    }

    @Test func exportFollowsSelectionOrderAndComputesResultsOnlyWhenAsked() throws {
        let db = try IAFixtures.makeDatabase()
        let exchange = RepositoryChildExchange(database: db, children: ChildRepository(database: db),
                                               visits: VisitRepository(database: db), parents: ParentRepository(database: db),
                                               addresses: AddressRepository(database: db),
                                               templates: AdditionalDataTemplateRepository(database: db),
                                               engine: try AnthroEngine.shared())
        #expect(try exchange.insertAll([complete, ExchangeChild(displayID: 6, firstName: "Bia", dateOfBirth: day("2017-01-20"), sex: .boy)]) == 2)
        let stored = try ChildRepository(database: db).list(archived: false)
        let ana = try #require(stored.first { $0.firstName == "Ana" }?.id)
        let bia = try #require(stored.first { $0.firstName == "Bia" }?.id)
        let plain = try exchange.exchangeChildren(ids: [bia, ana], includeResults: false)
        #expect(plain.map(\.firstName) == ["Bia", "Ana"])
        #expect(plain.last == complete)
        let withResults = try exchange.exchangeChildren(ids: [ana], includeResults: true)
        #expect(withResults.first?.visits.first?.results?.lengthOrHeightForAgeZ != nil)
        #expect(withResults.first?.visits.first?.results?.bmi == nil)
        #expect(try exchange.additionalDataDefinition().sections.map(\.identifier) == ["Maturation", "Physical activity", "Food", "Health"])
    }
}
