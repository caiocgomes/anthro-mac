import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum ChildExportFormat: CaseIterable, Sendable {
    case xml, tabText, semicolonCSV

    public var fileExtension: String { "" }
}

public enum ChildImportOutcome: Equatable, Sendable {
    case imported(count: Int)
    case failed(message: String)
}

/// Importação, exportação e relatório da Avaliação individual (`tsbChildrenImport_Click`, `tsbChildrenExport_Click`,
/// `GenerateChildReport`).
@MainActor
@Observable
public final class ChildExchangeModel {
    public var selectedChildIDs: [Int64] = []
    public var includeResults: Bool = false

    @ObservationIgnored private let source: any ChildExchangeSource
    @ObservationIgnored private let sink: any ChildImportSink

    public init(source: any ChildExchangeSource, sink: any ChildImportSink) {
        self.source = source
        self.sink = sink
    }

    public var canExport: Bool { false }

    public func export(format: ChildExportFormat, to url: URL) throws {}

    public func importXML(from url: URL) -> ChildImportOutcome { .imported(count: 0) }

    public func writeReport(childID: Int64, to url: URL) throws {}

    public func suggestedReportFileName(childID: Int64) throws -> String { "" }

    public static func message(for failure: ImportFailure, fileName: String) -> String { "" }
}
