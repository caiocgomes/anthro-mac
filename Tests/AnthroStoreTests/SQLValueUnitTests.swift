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

    @Test func dataViraTextoDeCalendarioEmUTC() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let date = utc.date(from: DateComponents(year: 2021, month: 4, day: 1, hour: 23, minute: 30))!
        #expect(SQLValue(date) == .text("2021-04-01"))
        #expect(SQLValue.text("2021-04-01").dateValue == utc.date(from: DateComponents(year: 2021, month: 4, day: 1)))
        #expect(SQLValue.text("01/04/2021").dateValue == nil)
    }
}
