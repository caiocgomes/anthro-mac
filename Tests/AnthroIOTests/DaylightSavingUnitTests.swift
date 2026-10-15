@testable import AnthroIO
import AnthroCore
import Foundation
import Testing

/// Datas de início do horário de verão: a meia-noite local não existe, e a leitura não pode depender dela.
@Suite("individual-data-exchange: datas no horário de verão (unitários)")
struct DaylightSavingUnitTests {
    private let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!

    @Test func transitionDaysAreReadInAnyTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = saoPaulo
        for text in ["16-10-2016 00:00:00", "16/10/2016", "2016-10-16", "16-10-2016", "04-11-2018 00:00:00", "25/10/1987"] {
            let date = try #require(FieldParser.parseDate(text, timeZone: saoPaulo), "\(text)")
            let parts = calendar.dateComponents([.day, .hour], from: date)
            #expect(parts.hour == 12, "\(text)")
            #expect(text.hasPrefix(String(format: "%02d", parts.day ?? 0)) || text.contains(String(format: "-%02d", parts.day ?? 0)), "\(text)")
        }
    }

    @Test func publicReaderAcceptsTransitionDaysInTheUsersTimeZone() throws {
        #expect(ymd(try FieldParser.date("16-10-2016 00:00:00", nullable: false)) == "2016-10-16")
        let children = try ChildXML.read(ChildXML.data([ExchangeChild(dateOfBirth: day("2016-10-16"), sex: .girl)], includeResults: false))
        #expect(ymd(children.first?.dateOfBirth) == "2016-10-16")
    }
}
