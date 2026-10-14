import AnthroCore
import AnthroFeatures
import Foundation
import Testing

@MainActor
@Suite("additional-data: editor de registro (unitários)")
struct RecordAdditionalDataUnitTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func editor(record: SurveyRecord? = nil, definition: String? = nil) -> RecordEditorModel {
        RecordEditorModel(record: record, survey: Survey(name: "Escola A", additionalDataDefinitionXML: definition,
                                                         options: SurveyFixtures.literalOptions()),
                          existingRecords: [], engine: engine, today: day("2026-10-14"), randomDay: { $0.lowerBound })
    }

    private func record(_ xml: String?) -> SurveyRecord {
        var record = SurveyFixtures.record(sex: .girl, visit: "2021-04-01", birth: "2015-01-01", weight: "20")
        record.id = 4
        record.additionalDataXML = xml
        return record
    }

    @Test func storedValueOutsideLimitDoesNotBlockUntouchedRecord() throws {
        let xml = #"<Data><Cat ID="A" Descr=""><Num Min="0" Max="10" ID="n" Descr="">12.345</Num></Cat></Data>"#
        let e = editor(record: record(xml))
        #expect(e.canSave)
        e.setText("21", for: .weight)
        #expect(try e.makeRecord().additionalDataXML == xml)
    }

    @Test func unreadableDefinitionIsCopiedIntactToNewRecord() throws {
        let definition = #"<Data><Cat ID="Escola" /></Data>"#
        let e = editor(definition: definition)
        #expect(e.additionalData.fields.isEmpty)
        #expect(try e.makeRecord().additionalDataXML == definition)
    }

    @Test func editedValueOfExistingRecordIsEncoded() throws {
        let e = editor(record: record(#"<Data><Cat ID="A" Descr=""><Num Min="" Max="" ID="n" Descr="">1.50</Num></Cat></Data>"#))
        e.additionalData.setNumber("2,5", section: 0, variable: 0)
        #expect(try e.makeRecord().additionalDataXML == #"<Data><Cat ID="A" Descr=""><Num Min="" Max="" ID="n" Descr="">2.5</Num></Cat></Data>"#)
    }

    @Test func invalidAdditionalValueMakesRecordThrow() {
        let e = editor(definition: #"<Data><Cat ID="A" Descr=""><Num Min="0" Max="10" ID="n" Descr="" /></Cat></Data>"#)
        e.additionalData.setNumber("x", section: 0, variable: 0)
        #expect(throws: AdditionalDataValueError(issues: [.invalid(section: "A", variable: "n")])) { try e.makeRecord() }
    }
}
