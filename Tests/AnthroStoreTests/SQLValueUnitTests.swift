import AnthroStore
import Foundation
import Testing

/// Laço interno de `SQLValue` (task 2.1, design D3).
@Suite("SQLValue: unidades")
struct SQLValueUnitTests {
    @Test func decimalViraTextoCanonico() {
        #expect(SQLValue(Decimal(string: "16.50")!) == .text("16.5"))
        #expect(SQLValue.text("16.5").decimalValue == Decimal(string: "16.5")!)
    }

    /// Dia de calendário do usuário (D10 da add-individual-assessment): grava o dia local e relê ao meio-dia local.
    @Test func dataViraTextoDoDiaDeCalendarioDoUsuario() {
        let calendar = Calendar.current
        let lateEvening = calendar.date(from: DateComponents(year: 2021, month: 4, day: 1, hour: 23, minute: 30))!
        let earlyMorning = calendar.date(from: DateComponents(year: 2021, month: 4, day: 1, hour: 0, minute: 30))!
        #expect(SQLValue(lateEvening) == .text("2021-04-01"))
        #expect(SQLValue(earlyMorning) == .text("2021-04-01"))
        #expect(SQLValue.text("2021-04-01").dateValue == calendar.date(from: DateComponents(year: 2021, month: 4, day: 1, hour: 12)))
        #expect(SQLValue.text("01/04/2021").dateValue == nil)
        #expect(SQLValue.text("2021-02-30").dateValue == nil)
    }
}
