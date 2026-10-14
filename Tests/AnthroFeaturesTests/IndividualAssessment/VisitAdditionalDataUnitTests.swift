import AnthroCore
import AnthroFeatures
import AnthroStore
import Foundation
import Testing

@MainActor
@Suite("additional-data: visita (unitários)")
struct VisitAdditionalDataUnitTests {
    private let engine = try! AnthroEngine.shared()

    private func editor(editing xml: String??, template: AdditionalData = AdditionalData()) -> VisitEditorModel {
        let visit = xml.map { VisitRecord(childID: 1, date: IAFixtures.date("2021-04-01"), weight: 20, lengthOrHeight: nil,
                                          measuredRecumbent: false, hasOedema: false, notes: nil, additionalDataXML: $0) }
        return VisitEditorModel(dateOfBirth: IAFixtures.date("2015-01-01"), sex: .girl, existingDates: [], editing: visit,
                                engine: engine, today: IAFixtures.date("2021-04-01"), newVisitAdditionalData: template)
    }

    @Test func untouchedVisitKeepsNilOrUnreadableXML() throws {
        #expect(try editor(editing: .some(nil)).makeVisit().additionalDataXML == nil)
        let unreadable = #"<Data><Cat ID="A" /></Data>"#
        #expect(try editor(editing: .some(unreadable)).makeVisit().additionalDataXML == unreadable)
        let raw = #"<Data><Cat ID="A" Descr=""><Num Min="0" Max="10" ID="n" Descr="">2.50</Num></Cat></Data>"#
        #expect(try editor(editing: .some(raw)).makeVisit().additionalDataXML == raw)
    }

    @Test func editedValueIsEncodedAndNewVisitStoresTemplate() throws {
        let raw = #"<Data><Cat ID="A" Descr=""><Txt ID="t" Descr="">a</Txt></Cat></Data>"#
        let existing = editor(editing: .some(raw))
        existing.additionalData.setText("b", section: 0, variable: 0)
        #expect(try existing.makeVisit().additionalDataXML == #"<Data><Cat ID="A" Descr=""><Txt ID="t" Descr="">b</Txt></Cat></Data>"#)

        let template = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola", variables: [textVariable("Série")])])
        let fresh = editor(editing: nil, template: template)
        #expect(fresh.additionalData.fields.map(\.label) == ["Série"])
        #expect(try fresh.makeVisit().additionalDataXML == #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt></Cat></Data>"#)
    }

    @Test func invalidAdditionalValueBlocksVisit() {
        let template = AdditionalData(sections: [AdditionalDataSection(identifier: "A", variables: [numberVariable("n", maximum: 10)])])
        let e = editor(editing: nil, template: template)
        e.weightText = "20"
        e.additionalData.setNumber("11", section: 0, variable: 0)
        #expect(!e.canSave)
        #expect(throws: AdditionalDataValueError.self) { try e.makeVisit() }
    }
}
