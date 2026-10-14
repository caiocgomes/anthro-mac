import AnthroFeatures
import Foundation
import Testing

/// Cenários de child-registry exercidos sobre `ParentEditorModel`.
@MainActor
@Suite("child-registry: ParentEditorModel")
struct ParentAddressEditorTests {
    let db: AnthroDatabase

    init() throws {
        db = try IAFixtures.makeDatabase()
    }

    private func editor(_ kind: ParentKind) -> ParentEditorModel {
        ParentEditorModel(kind: kind, database: db, editing: nil, today: { IAFixtures.date("2026-10-14") },
                          randomDay: { $0.lowerBound })
    }

    // Scenario: IMC truncado da mãe
    @Test func parentBMIIsTruncatedNotRounded() {
        let mother = editor(.mother)
        mother.weightText = "59"
        mother.heightText = "165"
        #expect(mother.bmiText == "21,6")
    }

    // Scenario: Altura fora do intervalo bloqueia o cadastro
    @Test func parentHeightOutsideRangeBlocksSave() throws {
        let father = editor(.father)
        father.weightText = "80"
        father.heightText = "40"
        #expect(father.heightOutcome == .outOfRange(50...300))
        #expect(father.heightWarning != nil)
        #expect(father.bmiText == "N/D")
        #expect(father.canSave == false)
        #expect(throws: ParentValidationError.invalidMeasurement) { try father.save() }
        #expect(try IAFixtures.count(db, "fathers") == 0)
    }

    // Scenario: Altura vazia é permitida
    @Test func parentWithEmptyHeightIsSaved() throws {
        let father = editor(.father)
        father.weightText = "80"
        father.heightText = ""
        #expect(father.canSave == true)
        try father.save()
        #expect(try IAFixtures.count(db, "fathers") == 1)
        let row = try #require(try IAFixtures.row(db, "fathers", where: "1 = 1"))
        #expect(row["weight"].decimalValue == 80)
        #expect(row["height"] == .null)
    }

    // Scenario: Nascimento desconhecido e futuro
    @Test func parentBirthDateUnknownOrFuture() throws {
        let future = editor(.mother)
        future.dateOfBirth = IAFixtures.date("2026-10-20")
        #expect(IAFixtures.ymd(future.dateOfBirth) == "2026-10-14")
        let unknown = editor(.mother)
        unknown.dateOfBirthUnknown = true
        let first = try unknown.save()
        let second = try future.save()
        let firstRow = try #require(try IAFixtures.row(db, "mothers", where: "mother_id = \(first.id ?? -1)"))
        let secondRow = try #require(try IAFixtures.row(db, "mothers", where: "mother_id = \(second.id ?? -1)"))
        #expect(firstRow["date_of_birth"] == .null)
        #expect(secondRow["date_of_birth"] == .text("2026-10-14"))
    }
}
