import AnthroIO
import Foundation
import Testing

@Suite("survey-data-exchange: texto (unitários)")
struct SurveyTextUnitTests {
    @Test func decodingCoversUTF16BigEndianPlainUTF8AndWindows1252Specials() {
        #expect(TextDecoding.decode(Data([0xFE, 0xFF, 0x00, 0x53, 0x00, 0x65, 0x00, 0x78])) == "Sex")
        #expect(TextDecoding.decode(Data("Conceição".utf8)) == "Conceição")
        #expect(TextDecoding.decode(Data([0x80, 0x20, 0x93, 0x61, 0x94])) == "€ \u{201C}a\u{201D}")
        #expect(TextDecoding.decode(Data()) == "")
    }

    @Test func separatorCountsTabsAndFallsBackOnTies() {
        #expect(SeparatorDetector.detect(firstLine: "Sex\tWeight\tHeight", fallback: ";") == "\t")
        #expect(SeparatorDetector.detect(firstLine: "a,b;c", fallback: "\t") == "\t")
        #expect(SeparatorDetector.detect(firstLine: "a;b;c,d", fallback: "\t") == ";")
        // O padrão da extensão presente na linha vence a contagem (D20).
        #expect(SeparatorDetector.detect(firstLine: "a;b;c,d", fallback: ",") == ",")
    }

    @Test func fileKindIgnoresCaseAndKnowsDefaults() {
        #expect(SurveyFileKind.forFileExtension("CSV") == .delimited(fallbackSeparator: ";"))
        #expect(SurveyFileKind.forFileExtension("txt") == .delimited(fallbackSeparator: "\t"))
        #expect(SurveyFileKind.forFileExtension("REC") == .rec)
        #expect(SurveyFileKind.forFileExtension("DBF") == .dbf)
        #expect(SurveyFileKind.forFileExtension("") == .xml)
    }

    @Test func parserHandlesLineEndingsQuotesAndHeaders() throws {
        #expect(try DelimitedParser.parse("A;B\r1;2\r3;4", separator: ";").rows == [["1", "2"], ["3", "4"]])
        #expect(try DelimitedParser.parse("Sex;sex\n1;2\n", separator: ";").columns == ["Sex", "Column1"])
        #expect(try DelimitedParser.parse("A;B\n\"x\"y;2\n", separator: ";").rows == [["xy", "2"]])
        #expect(try DelimitedParser.parse("A;B\n1;\n", separator: ";").rows == [["1", ""]])
        #expect(try DelimitedParser.parse("A\n   \n1\n", separator: ";").rows == [["1"]])
        // Linha só de campos vazios não é registro (D20).
        #expect(try DelimitedParser.parse("A;B\n;\n", separator: ";").rows == [])
        #expect(try DelimitedParser.parse("Column1;;A\n1;2;3\n", separator: ";").columns == ["Column1", "Column2", "A"])
    }

    @Test func blankOnlyTextIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try DelimitedParser.parse("\r\n\r\n", separator: ";") }
    }
}
