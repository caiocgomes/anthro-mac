import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `SurveyOptionsEditorModel`: faixas e limites de z.
@MainActor
@Suite("SurveyOptionsEditorModel: unidades")
struct SurveyOptionsEditorUnitTests {
    private func editor() -> SurveyOptionsEditorModel {
        SurveyOptionsEditorModel(options: SurveyFixtures.literalOptions())
    }

    @Test func addingBeyondTwentyOneGroupsDoesNothing() {
        let e = editor()
        #expect(e.ageGroups.count == 21)
        e.addAgeGroup()
        #expect(e.ageGroups.count == 21)
        e.removeAgeGroup(at: 20)
        e.removeAgeGroup(at: 19)
        #expect(e.lowerBounds.last == 204)
        e.addAgeGroup()
        #expect(e.ageGroups.count == 20)
        #expect(e.lowerBounds.last == 205)
    }

    @Test func removingAGroupWidensThePreviousOne() throws {
        let e = editor()
        e.removeAgeGroup(at: 1)
        #expect(e.ageGroups.first == AgeGroup(lowerMonths: 0, upperMonths: 11))
        #expect(try e.apply().ageGroupBoundaries.prefix(3) == [0, 12, 24])
    }

    @Test func appliedBoundariesAreLowerBoundsPlusLastUpper() throws {
        let e = editor()
        for _ in 0..<30 where e.ageGroups.count > 2 { e.removeAgeGroup(at: e.ageGroups.count - 1) }
        e.setLowerBound(61, at: 1)
        e.lastUpperBound = 120
        #expect(try e.apply().ageGroupBoundaries == [0, 61, 120])
    }

    @Test func boundsOutsideZeroTo228OrLastUpperBelowLowerAreInconsistent() {
        let e = editor()
        e.setLowerBound(229, at: 20)
        #expect(throws: SurveyOptionsEditorError.inconsistentAgeGroups) { try e.apply() }
        let f = editor()
        f.setLowerBound(200, at: 20)
        f.lastUpperBound = 199
        #expect(throws: SurveyOptionsEditorError.inconsistentAgeGroups) { try f.apply() }
    }

    @Test func invalidZTextKeepsBoundUntilFixed() throws {
        let e = editor()
        e.setZBound(text: "abc", indicator: .lengthOrHeightForAge, range: .reference, isMax: false)
        #expect(e.zBoundOutcome(.lengthOrHeightForAge, range: .reference, isMax: false) == .invalid)
        #expect(e.zBound(.lengthOrHeightForAge, range: .reference, isMax: false) == -6)
        #expect(throws: SurveyOptionsEditorError.invalidZBounds) { try e.apply() }
        e.setZBound(text: "-4,57", indicator: .lengthOrHeightForAge, range: .reference, isMax: false)
        #expect(try e.apply().referenceMinZ == [-6, num("-4.5"), -5])
    }

    @Test func autoIDTogglesAreApplied() throws {
        let e = editor()
        e.autoIDCluster = true
        e.autoIDRecord = false
        let applied = try e.apply()
        #expect(applied.autoIDCluster)
        #expect(applied.autoIDRecord == false)
    }
}
