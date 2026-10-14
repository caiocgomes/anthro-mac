import AnthroFeatures
import Foundation
import Testing

/// Cenários do editor de opções do inquérito (change add-nutritional-survey).
@MainActor
@Suite("survey-management: editor de opções")
struct SurveyOptionsEditorScenarioTests {
    private func editor() -> SurveyOptionsEditorModel {
        SurveyOptionsEditorModel(options: SurveyFixtures.literalOptions())
    }

    /// Remove as últimas faixas até sobrarem `count` (no máximo 30 tentativas).
    private func keep(_ count: Int, groupsIn e: SurveyOptionsEditorModel) {
        for _ in 0..<30 where e.ageGroups.count > count {
            e.removeAgeGroup(at: e.ageGroups.count - 1)
        }
    }

    // Scenario: Menos de duas faixas
    @Test func applyingWithOneAgeGroupThrowsTooFew() {
        let e = editor()
        keep(1, groupsIn: e)
        #expect(e.ageGroups.count == 1)
        #expect(throws: SurveyOptionsEditorError.tooFewAgeGroups) { try e.apply() }
    }

    // Scenario: Limites inferiores repetidos
    @Test func repeatedLowerBoundsThrowInconsistent() {
        let e = editor()
        keep(3, groupsIn: e)
        e.setLowerBound(12, at: 1)
        e.setLowerBound(12, at: 2)
        #expect(e.lowerBounds == [0, 12, 12])
        #expect(throws: SurveyOptionsEditorError.inconsistentAgeGroups) { try e.apply() }
    }

    // Scenario: Máximo abaixo do mínimo
    @Test func maxBelowMinIsRaisedToMin() {
        let e = editor()
        e.setZBound(text: "-7", indicator: .weightForAge, range: .standards, isMax: true)
        #expect(e.zBound(.weightForAge, range: .standards, isMax: true) == -6)
    }

    // Scenario: Mínimo acima do máximo e limite fora da faixa
    @Test func minAboveMaxIsLoweredAndOutOfRangeBoundBlocksApply() {
        let e = editor()
        e.setZBound(text: "6", indicator: .bmiForAge, range: .reference, isMax: false)
        #expect(e.zBound(.bmiForAge, range: .reference, isMax: false) == 5)
        e.setZBound(text: "120", indicator: .bmiForAge, range: .reference, isMax: true)
        #expect(e.zBoundOutcome(.bmiForAge, range: .reference, isMax: true) == .outOfRange(-99...99))
        #expect(e.zBound(.bmiForAge, range: .reference, isMax: true) == 5)
        #expect(throws: SurveyOptionsEditorError.invalidZBounds) { try e.apply() }
    }

    // Scenario: Restaurar depois de alterar
    @Test func resetRestoresLiteralDefaults() throws {
        let e = editor()
        e.autoIDTeam = true
        e.setZBound(text: "4", indicator: .lengthOrHeightForAge, range: .standards, isMax: true)
        e.removeAgeGroup(at: 3)
        e.resetToDefaults()
        SurveyFixtures.expectLiteralDefaults(try e.apply())
    }

    // Scenario: Restaurar sem alterações
    @Test func resetOnDefaultsKeepsLiteralDefaults() throws {
        let e = editor()
        e.resetToDefaults()
        SurveyFixtures.expectLiteralDefaults(try e.apply())
    }
}
