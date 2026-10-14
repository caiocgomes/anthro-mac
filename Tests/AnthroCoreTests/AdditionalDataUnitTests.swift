import AnthroCore
import Foundation
import Testing

@Suite("additional-data: buscas e escrita (unitários)")
struct AdditionalDataUnitTests {
    private let data = AdditionalData(sections: [
        AdditionalDataSection(identifier: "A", variables: [
            AdditionalDataVariable(identifier: "x", kind: .text("primeiro")),
            AdditionalDataVariable(identifier: "x", kind: .text("segundo")),
        ]),
        AdditionalDataSection(identifier: "B", variables: [AdditionalDataVariable(identifier: "y", kind: .date(nil))]),
        AdditionalDataSection(identifier: "A"),
    ])

    @Test func sectionReturnsFirstMatchLikeFindSection() {
        #expect(data.section("A")?.variables.count == 2)
        #expect(data.section("B")?.identifier == "B")
        #expect(data.section("a") == nil)
        #expect(data.section("C") == nil)
    }

    @Test func variableLooksUpSectionThenVariable() {
        #expect(data.variable(section: "A", variable: "x")?.kind == .text("primeiro"))
        #expect(data.variable(section: "B", variable: "y")?.kind == .date(nil))
        #expect(data.variable(section: "B", variable: "x") == nil)
        #expect(data.variable(section: "Z", variable: "x") == nil)
        #expect(data.sections[0].variable("x")?.kind == .text("primeiro"))
    }

    @Test func encodeEscapesAttributesAndText() throws {
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: #"A&B <"x">"#, description: "d>e", variables: [
            AdditionalDataVariable(identifier: "t", kind: .text(#"1 < 2 & "3" > 0"#)),
        ])])
        #expect(AdditionalDataXML.encode(data)
            == #"<Data><Cat ID="A&amp;B &lt;&quot;x&quot;&gt;" Descr="d&gt;e"><Txt ID="t" Descr="">1 &lt; 2 &amp; "3" &gt; 0</Txt></Cat></Data>"#)
        #expect(try AdditionalDataXML.decode(AdditionalDataXML.encode(data)) == data)
    }

    @Test func encodeWritesEmptyNumberAndDateSelfClosingAndLimitsWithPoint() {
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: "S", variables: [
            AdditionalDataVariable(identifier: "n", kind: .number(value: nil, minimum: Decimal(string: "-0.5"), maximum: 99)),
            AdditionalDataVariable(identifier: "d", kind: .date(nil)),
        ])])
        #expect(AdditionalDataXML.encode(data)
            == #"<Data><Cat ID="S" Descr=""><Num Min="-0.5" Max="99" ID="n" Descr="" /><Date ID="d" Descr="" /></Cat></Data>"#)
    }

    @Test func dateIsWrittenAsTheLocalCalendarDayAndReadAtNoon() throws {
        let lateEvening = localDate(2021, 4, 1, hour: 23, minute: 30)
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: "S", variables: [
            AdditionalDataVariable(identifier: "d", kind: .date(lateEvening)),
        ])])
        let xml = AdditionalDataXML.encode(data)
        #expect(xml.contains(">01-04-2021 00:00:00</Date>"))
        #expect(try AdditionalDataXML.decode(xml).variable(section: "S", variable: "d")?.kind == .date(localDate(2021, 4, 1)))
    }

    @Test func impossibleOrLooseDatesAreReadAsNil() throws {
        for text in ["31-02-2020 00:00:00", "15-13-2020 00:00:00", "15-03-2020 24:00:00", " 15-03-2020 00:00:00",
                     "15-03-2020", "2020-03-15 00:00:00"] {
            let xml = #"<Data><Cat ID="S" Descr=""><Date ID="d" Descr="">"# + text + "</Date></Cat></Data>"
            #expect(try AdditionalDataXML.decode(xml).variable(section: "S", variable: "d")?.kind == .date(nil), "\(text)")
        }
        let timed = #"<Data><Cat ID="S" Descr=""><Date ID="d" Descr="">29-02-2020 14:05:09</Date></Cat></Data>"#
        #expect(try AdditionalDataXML.decode(timed).variable(section: "S", variable: "d")?.kind == .date(localDate(2020, 2, 29)))
    }

    @Test func decodeFindsSectionsUnderAnyRootAndKeepsUntrimmedText() throws {
        let xml = #"<Outro><x><Cat ID="A" Descr="desc"><Txt ID="t" Descr=""> a </Txt><Num Min="1" Max="" ID="n" Descr=""> 2.5 </Num></Cat></x></Outro>"#
        let data = try AdditionalDataXML.decode(xml)
        #expect(data == AdditionalData(sections: [AdditionalDataSection(identifier: "A", description: "desc", variables: [
            AdditionalDataVariable(identifier: "t", kind: .text(" a ")),
            AdditionalDataVariable(identifier: "n", kind: .number(value: Decimal(string: "2.5"), minimum: 1, maximum: nil)),
        ])]))
    }

    @Test func decodeRejectsMalformedXMLAndMissingNumberLimits() {
        #expect(throws: AdditionalDataXMLError.self) { try AdditionalDataXML.decode("<Data><Cat ID=\"A\" Descr=\"\">") }
        #expect(throws: AdditionalDataXMLError.self) {
            try AdditionalDataXML.decode(#"<Data><Cat ID="A" Descr=""><Num Max="" ID="n" Descr="" /></Cat></Data>"#)
        }
        #expect(throws: AdditionalDataXMLError.self) {
            try AdditionalDataXML.decode(#"<Data><Cat Descr=""></Cat></Data>"#)
        }
    }

    @Test func pastedControlCharactersDoNotMakeUnreadableXML() throws {
        let data = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola\u{0B}A", description: "x\u{00}y", variables: [
            AdditionalDataVariable(identifier: "t", kind: .text("3º ano\u{0B}B\u{0C}C\u{1B}\u{FFFE}")),
        ])])
        let reread = try AdditionalDataXML.decode(AdditionalDataXML.encode(data))
        #expect(reread.sections.first?.identifier == "Escola A")
        #expect(reread.sections.first?.description == "xy")
        #expect(reread.variable(section: "Escola A", variable: "t")?.kind == .text("3º ano B C"))
        let kept = AdditionalData(sections: [AdditionalDataSection(identifier: "S", variables: [
            AdditionalDataVariable(identifier: "t", kind: .text("linha 1\nlinha 2\ttab 😀")),
        ])])
        #expect(try AdditionalDataXML.decode(AdditionalDataXML.encode(kept)) == kept)
    }
}

