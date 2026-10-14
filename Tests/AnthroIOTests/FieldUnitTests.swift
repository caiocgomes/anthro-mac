import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("individual-data-exchange: campos (unitários)")
struct FieldUnitTests {
    @Test func writerHandlesNilNegativeIntegersAndText() {
        #expect(FieldWriter.decimal(nil, style: .comma) == "")
        #expect(FieldWriter.decimal(d("-1.250"), style: .comma) == "-1,25")
        #expect(FieldWriter.decimal(d("140"), style: .point) == "140")
        #expect(FieldWriter.integer(7) == "7")
        #expect(FieldWriter.integer(nil) == "")
        #expect(FieldWriter.text(nil) == "")
        #expect(FieldWriter.text("Ana") == "Ana")
        #expect(FieldWriter.sex(nil) == "")
        #expect(FieldWriter.boolean(nil) == "")
        #expect(FieldWriter.measureType(nil) == "")
        let lateEvening = Calendar.current.date(byAdding: .hour, value: 11, to: day("2021-04-01"))!
        #expect(FieldWriter.date(lateEvening) == "01-04-2021 00:00:00")
    }

    @Test func nullableEmptyAndAbsentAreNilButRequiredAreErrors() throws {
        #expect(try FieldParser.text(nil, nullable: true) == nil)
        #expect(try FieldParser.text("", nullable: true) == nil)
        #expect(try FieldParser.text("", nullable: false) == "")
        #expect(throws: FieldParseError.missing) { try FieldParser.text(nil, nullable: false) }
        #expect(throws: FieldParseError.missing) { try FieldParser.sex(nil) }
        #expect(try FieldParser.decimal("", nullable: true, unsigned: true) == nil)
        #expect(throws: FieldParseError.invalid) { try FieldParser.decimal("", nullable: false, unsigned: true) }
        #expect(try FieldParser.boolean("YES", nullable: false) == true)
        #expect(try FieldParser.boolean("n", nullable: false) == false)
        #expect(throws: FieldParseError.invalid) { try FieldParser.boolean(" 1", nullable: false) }
        #expect(try FieldParser.measureType("L") == true)
        #expect(try FieldParser.measureType("h") == false)
        #expect(throws: FieldParseError.invalid) { try FieldParser.measureType("x") }
    }

    @Test func numbersAreTruncatedBeforeLimitsAndUnsignedRejectsNegatives() throws {
        #expect(try FieldParser.decimal("16.789", nullable: false, unsigned: true) == d("16.78"))
        #expect(try FieldParser.decimal("-16.789", nullable: false, unsigned: false) == d("-16.78"))
        #expect(throws: FieldParseError.outOfRange) { try FieldParser.decimal("-1", nullable: false, unsigned: true) }
        #expect(throws: FieldParseError.outOfRange) {
            try FieldParser.decimal("0.899", nullable: false, unsigned: true, min: d("0.9"))
        }
        #expect(try FieldParser.decimal("275.009", nullable: false, unsigned: true, max: 275) == 275)
        #expect(throws: FieldParseError.invalid) { try FieldParser.decimal("1e3", nullable: false, unsigned: true) }
        #expect(throws: FieldParseError.invalid) { try FieldParser.decimal("1.2.3", nullable: false, unsigned: true) }
        #expect(try FieldParser.decimal("1.23456", nullable: false, unsigned: true, truncateToPlaces: nil) == d("1.23456"))
        #expect(try FieldParser.unsignedInteger("12", nullable: true) == 12)
        #expect(throws: FieldParseError.outOfRange) { try FieldParser.unsignedInteger("-3", nullable: false) }
        #expect(throws: FieldParseError.invalid) { try FieldParser.unsignedInteger("1,5", nullable: false) }
        #expect(try FieldParser.text("abcdef", nullable: false, maxLength: 3) == "abc")
    }

    @Test func datesFollowTheFallbackListAndLimitsCompareDays() throws {
        for text in ["15-03-2016 00:00:00", "15/03/2016 23:59:00", "2016-03-15", "2016-03-15T08:00:00", "15-03-2016", "20160315xyz"] {
            #expect(try FieldParser.date(text, nullable: false) == day("2016-03-15"), "\(text)")
        }
        for text in ["31-02-2016 00:00:00", "31/02/2016", "2016-13-01", "março de 2016", "2016031"] {
            #expect(throws: FieldParseError.invalid, "\(text)") { try FieldParser.date(text, nullable: false) }
        }
        #expect(try FieldParser.date("15-03-2016", nullable: false, notBefore: day("2016-03-15")) == day("2016-03-15"))
        #expect(throws: FieldParseError.outOfRange) {
            try FieldParser.date("14-03-2016", nullable: false, notBefore: day("2016-03-15"))
        }
        #expect(throws: FieldParseError.outOfRange) {
            try FieldParser.date("16-03-2016", nullable: false, notAfter: day("2016-03-15"))
        }
        #expect(try FieldParser.date("", nullable: true) == nil)
    }
}
