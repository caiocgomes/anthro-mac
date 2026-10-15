import AnthroCore
import AnthroIO
import AnthroStore
import Foundation

/// Conversões entre as estruturas de troca e os registros da Avaliação individual (design D1): `height` é
/// `lengthOrHeight`, `isRecumbent` é `measuredRecumbent`, e os dados adicionais passam pelo codec da change 6. Os campos
/// de acompanhamento não fazem parte da troca.
public enum ChildExchangeMapping {
    public static func exchange(child: ChildRecord, mother: ParentRecord?, father: ParentRecord?, address: AddressRecord?,
                                visits: [VisitRecord]) throws -> ExchangeChild {
        ExchangeChild(displayID: child.displayID, firstName: child.firstName, lastName: child.lastName,
                      dateOfBirth: child.dateOfBirth, dateOfBirthIsApprox: child.dateOfBirthIsApprox, sex: child.sex,
                      notes: child.notes, mother: mother.map(person), father: father.map(person),
                      address: address.map(exchangeAddress),
                      visits: try visits.map { visit in
                          ExchangeVisit(date: visit.date, weight: visit.weight, height: visit.lengthOrHeight,
                                        isRecumbent: visit.measuredRecumbent, hasOedema: visit.hasOedema, notes: visit.notes,
                                        additionalData: try visit.additionalDataXML.map(AdditionalDataXML.decode))
                      })
    }

    public static func records(from child: ExchangeChild) throws -> (child: ChildRecord, mother: ParentRecord?,
                                                                     father: ParentRecord?, address: AddressRecord?,
                                                                     visits: [VisitRecord]) {
        let record = ChildRecord(displayID: child.displayID, firstName: child.firstName, lastName: child.lastName,
                                 dateOfBirth: child.dateOfBirth, dateOfBirthIsApprox: child.dateOfBirthIsApprox,
                                 sex: child.sex, notes: child.notes)
        let visits = child.visits.map { visit in
            VisitRecord(date: visit.date, weight: visit.weight, lengthOrHeight: visit.height,
                        measuredRecumbent: visit.isRecumbent, hasOedema: visit.hasOedema, notes: visit.notes,
                        additionalDataXML: visit.additionalData.map(AdditionalDataXML.encode))
        }
        return (record, child.mother.map { parent($0, kind: .mother) }, child.father.map { parent($0, kind: .father) },
                child.address.map(addressRecord), visits)
    }

    // MARK: Privado

    private static func person(_ parent: ParentRecord) -> ExchangePerson {
        ExchangePerson(firstName: parent.firstName, lastName: parent.lastName, height: parent.height, weight: parent.weight,
                       dateOfBirth: parent.dateOfBirth, dateOfBirthIsApprox: parent.dateOfBirthIsApprox, notes: parent.notes)
    }

    private static func parent(_ person: ExchangePerson, kind: ParentKind) -> ParentRecord {
        ParentRecord(kind: kind, firstName: person.firstName, lastName: person.lastName, height: person.height,
                     weight: person.weight, dateOfBirth: person.dateOfBirth, dateOfBirthIsApprox: person.dateOfBirthIsApprox,
                     notes: person.notes)
    }

    private static func exchangeAddress(_ address: AddressRecord) -> ExchangeAddress {
        ExchangeAddress(streetInfo: address.streetInfo, place: address.place, zip: address.zip, district: address.district,
                        province: address.province, state: address.state, country: address.country,
                        phoneNumber: address.phoneNumber, email: address.email)
    }

    private static func addressRecord(_ address: ExchangeAddress) -> AddressRecord {
        AddressRecord(streetInfo: address.streetInfo, place: address.place, zip: address.zip, district: address.district,
                      province: address.province, state: address.state, country: address.country,
                      phoneNumber: address.phoneNumber, email: address.email)
    }
}
