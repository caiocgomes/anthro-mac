import AnthroCore
import Foundation

/// `Child.ExportChildrenToDelimitedFile`: 43 colunas, resultados opcionais e colunas de dados adicionais.
public enum ChildDelimitedExport {
    public static let baseColumns: [String] = []
    public static let resultColumns: [String] = []

    public static func data(_ children: [ExchangeChild], additionalDefinition: AdditionalData, includeResults: Bool,
                            format: DelimitedFormat) -> Data {
        Data()
    }
}
