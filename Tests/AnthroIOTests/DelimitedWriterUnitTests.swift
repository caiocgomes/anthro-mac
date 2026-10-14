import AnthroIO
import Foundation
import Testing

@Suite("individual-data-exchange: escritor delimitado (unitários)")
struct DelimitedWriterUnitTests {
    @Test func lineBreaksOfAnyKindAreQuoted() {
        #expect(DelimitedWriter.write(header: ["N"], rows: [["a\r\nb"], ["c\nd"], ["e\rf"]], separator: ";")
            == "N\r\n\"a\r\nb\"\r\n\"c\nd\"\r\n\"e\rf\"\r\n")
    }

    @Test func formatsExposeSeparatorAndExtension() {
        #expect(DelimitedFormat.tabText.separator == "\t")
        #expect(DelimitedFormat.semicolonCSV.separator == ";")
        #expect(DelimitedFormat.tabText.fileExtension == "txt")
        #expect(DelimitedFormat.semicolonCSV.fileExtension == "csv")
        #expect(Array(DelimitedWriter.utf8WithBOM("a")) == [0xEF, 0xBB, 0xBF, 0x61])
    }
}
