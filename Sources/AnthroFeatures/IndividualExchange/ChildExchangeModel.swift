import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum ChildExportFormat: CaseIterable, Sendable {
    case xml, tabText, semicolonCSV

    public var fileExtension: String {
        switch self {
        case .xml: "xml"
        case .tabText: DelimitedFormat.tabText.fileExtension
        case .semicolonCSV: DelimitedFormat.semicolonCSV.fileExtension
        }
    }
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
    /// Crianças marcadas, na ordem da lista.
    public var selectedChildIDs: [Int64] = []
    /// A pergunta "incluir resultados?" do original começa com não.
    public var includeResults: Bool = false
    /// Aviso da última importação aceita: textos cortados nos limites do original.
    public private(set) var lastImportWarning: String?

    @ObservationIgnored private let source: any ChildExchangeSource
    @ObservationIgnored private let sink: any ChildImportSink

    public init(source: any ChildExchangeSource, sink: any ChildImportSink) {
        self.source = source
        self.sink = sink
    }

    public var canExport: Bool {
        !selectedChildIDs.isEmpty
    }

    /// As crianças marcadas no formato escolhido; TXT e CSV levam as colunas do modelo de dados adicionais.
    public func export(format: ChildExportFormat, to url: URL) throws {
        let children = try source.exchangeChildren(ids: selectedChildIDs, includeResults: includeResults)
        let data: Data = switch format {
        case .xml:
            ChildXML.data(children, includeResults: includeResults)
        case .tabText:
            ChildDelimitedExport.data(children, additionalDefinition: try source.additionalDataDefinition(),
                                      includeResults: includeResults, format: .tabText)
        case .semicolonCSV:
            ChildDelimitedExport.data(children, additionalDefinition: try source.additionalDataDefinition(),
                                      includeResults: includeResults, format: .semicolonCSV)
        }
        try data.write(to: url, options: .atomic)
    }

    /// Lê o XML inteiro antes de gravar: qualquer falha rejeita o arquivo sem tocar no banco (design D6 e D10).
    public func importXML(from url: URL) -> ChildImportOutcome {
        lastImportWarning = nil
        let fileName = url.lastPathComponent
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failed(message: "\(Self.prefix(fileName)) \(L10n.Exchange.unreadableFile)")
        }
        let report: (children: [ExchangeChild], truncated: [ImportFieldError])
        do {
            report = try ChildXML.readReport(data)
        } catch {
            return .failed(message: Self.message(for: error, fileName: fileName))
        }
        do {
            let count = try sink.insertAll(report.children)
            if let first = report.truncated.first {
                lastImportWarning = "\(L10n.Exchange.truncatedPrefix) \(report.truncated.count) \(L10n.Exchange.truncatedSuffix) "
                    + "\(L10n.Exchange.firstCase) \(L10n.Exchange.line) \(first.line), \(first.field)."
            }
            return .imported(count: count)
        } catch {
            return .failed(message: "\(Self.prefix(fileName)) \(L10n.IndividualAssessment.databaseError) \(error)")
        }
    }

    /// Relatório da criança com os resultados calculados.
    public func writeReport(childID: Int64, to url: URL) throws {
        try ChildReport.data(for: try child(childID)).write(to: url, options: .atomic)
    }

    public func suggestedReportFileName(childID: Int64) throws -> String {
        ChildReport.suggestedFileName(for: try child(childID))
    }

    /// `Utils.DisplayImportError` em pt-BR, com o detalhe de linha, elemento e atributo quando a leitura o informa.
    public static func message(for failure: ImportFailure, fileName: String) -> String {
        let reason: String
        var detail: ImportFailureDetail?
        switch failure {
        case .invalidStructure(let found):
            reason = L10n.Exchange.invalidStructure
            detail = found
        case .missingField:
            reason = L10n.Exchange.missingField
        case .invalidFieldValue:
            reason = L10n.Exchange.invalidFieldValue
        }
        var message = "\(prefix(fileName)) \(reason)"
        if let detail {
            let parts = [detail.line.map { "\(L10n.Exchange.line) \($0)" },
                         detail.element.map { "\(L10n.Exchange.element) \($0)" },
                         detail.attribute.map { "\(L10n.Exchange.attribute) \($0)" }].compactMap { $0 }
            if !parts.isEmpty { message += " \(L10n.Exchange.detail) \(parts.joined(separator: ", "))." }
        }
        return message
    }

    // MARK: Privado

    private static func prefix(_ fileName: String) -> String {
        "\(L10n.Exchange.importFailedPrefix) '\(fileName)':"
    }

    private func child(_ id: Int64) throws -> ExchangeChild {
        guard let child = try source.exchangeChildren(ids: [id], includeResults: true).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return child
    }
}
