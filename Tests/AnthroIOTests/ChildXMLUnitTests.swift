import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("individual-data-exchange: XML de crianças (unitários)")
struct ChildXMLUnitTests {
    private typealias F = ExchangeFixtures

    @Test func failureCarriesLineElementAndAttribute() {
        let data = F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["Height": "300"]))))
        #expect(throws: ImportFailure.invalidStructure(ImportFailureDetail(line: 3, element: "Visit", attribute: "Height"))) {
            try ChildXML.read(data)
        }
    }

    @Test func visitCreatedByIsRequiredButChildCreatedByIsNot() throws {
        expectInvalidStructure(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["CreatedBy": nil])))))
        #expect(try ChildXML.read(F.xml(F.child(["CreatedBy": nil]))).count == 1)
    }

    @Test func brokenXMLIsInvalidStructure() {
        expectInvalidStructure(Data("<Children><Child DisplayID=\"1\"".utf8))
    }

    @Test func tabsAndLineBreaksInTextSurviveTheRoundTrip() throws {
        let child = F.ana(notes: "linha 1\r\nlinha 2\tcom tab", visits: [F.visit("2021-04-01", weight: "18", notes: "a\nb")])
        #expect(try ChildXML.read(ChildXML.data([child], includeResults: false)).first?.notes == "linha 1\r\nlinha 2\tcom tab")
        #expect(try ChildXML.read(ChildXML.data([child], includeResults: false)).first?.visits.first?.notes == "a\nb")
    }

    @Test func documentStartsWithBOMAndDeclarationAndUsesCRLF() {
        let data = ChildXML.data([F.ana()], includeResults: false)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
        let text = String(decoding: data.dropFirst(3), as: UTF8.self)
        #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\r\n<Children>\r\n  <Child "))
        #expect(String(decoding: ChildXML.data([], includeResults: false).dropFirst(3), as: UTF8.self).hasSuffix("<Children />"))
    }

    @Test func emptyAdditionalDataAttributeIsNil() throws {
        let children = try ChildXML.read(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["AdditionalData": ""])))))
        #expect(children.first?.visits.first?.additionalData == nil)
    }

    @Test func nestedChildIsInvalidStructureNotACrash() {
        let inner = F.child(["DisplayID": "2"], inner: F.visits(F.visitXML("01-04-2021 00:00:00")))
        expectInvalidStructure(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00")) + inner)))
    }

    @Test func elementsOutsideAChildAreInvalidStructure() {
        expectInvalidStructure(F.xml(F.visits(F.visitXML("01-04-2021 00:00:00")) + F.child()))
        let mother = "<Mother FirstName=\"Maria\" LastName=\"\" Height=\"\" Weight=\"\" DateOfBirth=\"\" DateOfBirthIsApprox=\"0\" Notes=\"\" CreatedBy=\"\" />"
        expectInvalidStructure(F.xml(F.child() + mother))
    }

    @Test func displayIDAboveTheOriginalIntegerIsInvalidStructure() throws {
        expectInvalidStructure(F.xml(F.child(["DisplayID": "2147483648"])))
        #expect(try ChildXML.read(F.xml(F.child(["DisplayID": "2147483647"]))).first?.displayID == 2_147_483_647)
    }

    @Test func truncatedTextsAreReportedWithLineAndField() throws {
        let long = String(repeating: "a", count: 260)
        let report = try ChildXML.readReport(F.xml(F.child(["Notes": long], inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["Notes": long])))))
        #expect(report.children.first?.notes?.count == 250)
        #expect(report.truncated == [ImportFieldError(line: 3, field: "Child.Notes"), ImportFieldError(line: 3, field: "Visit.Notes")])
        #expect(try ChildXML.readReport(F.xml(F.child())).truncated.isEmpty)
    }

    @Test func discardedFieldsDoNotCountAsTruncatedTexts() throws {
        let longAuthor = String(repeating: "o", count: 30)
        let address = "<Address StreetInfo=\"\" Place=\"\" ZIP=\"\" District=\"\" Province=\"\" State=\"\" Country=\"\" SALBLevel1=\"12345\" SALBLevel2=\"6789\" PhoneNumber=\"\" Email=\"\" CreatedBy=\"\(longAuthor)\" />"
        let report = try ChildXML.readReport(F.xml(F.child(["CreatedBy": longAuthor],
                                                           inner: address + F.visits(F.visitXML("01-04-2021 00:00:00", ["CreatedBy": longAuthor])))))
        #expect(report.children.count == 1)
        #expect(report.truncated.isEmpty)
    }
}

