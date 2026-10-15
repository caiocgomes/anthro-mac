import AnthroAnalysis
import Foundation

/// Relatório padrão (com ou sem correção por cluster) ou de estimativas do banco global da OMS.
public enum SurveyReportKind: Sendable, Equatable {
    case standard(improvedClusterAnalysis: Bool)
    case estimates
}

/// Linhas do relatório sem terminador (design D8); `text` junta com CRLF e `table` divide por tabulação.
public struct SurveyReport: Sendable, Equatable {
    public let kind: SurveyReportKind
    public let lines: [String]

    public init(kind: SurveyReportKind, lines: [String]) {
        self.kind = kind
        self.lines = lines
    }

    /// Cada linha terminada em CRLF, como `StringBuilder.AppendLine` no Windows.
    public var text: String {
        lines.map { $0 + "\r\n" }.joined()
    }

    /// Uma linha por linha do texto e uma célula por campo separado por tabulação; linha vazia tem uma célula vazia.
    public var table: [[String]] {
        lines.map { $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
    }
}
