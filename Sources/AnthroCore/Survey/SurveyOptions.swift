import Foundation

/// Opções do inquérito (`SurveyOptions` do original, design D9): atribuição automática de IDs, fronteiras das faixas
/// etárias e limites de z de plausibilidade por indicador (índice `Indicator.rawValue`) para padrões e referência.
public struct SurveyOptions: Sendable, Equatable {
    public var autoIDCluster: Bool
    public var autoIDTeam: Bool
    public var autoIDRecord: Bool
    public var autoIDHousehold: Bool
    public var ageGroupBoundaries: [Int]
    public var standardsMinZ: [Decimal]
    public var standardsMaxZ: [Decimal]
    public var referenceMinZ: [Decimal]
    public var referenceMaxZ: [Decimal]

    /// Padrões de `SurveyOptions` e `AnthroComputation.STD_MINZSCOREBOUNDS` etc.
    public static let `default` = SurveyOptions(
        autoIDCluster: false, autoIDTeam: false, autoIDRecord: true, autoIDHousehold: true,
        ageGroupBoundaries: [0, 6, 12, 24, 36, 48, 61, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 228, 228],
        standardsMinZ: [-6, -6, -5], standardsMaxZ: [5, 6, 5], referenceMinZ: [-6, -6, -5], referenceMaxZ: [5, 6, 5]
    )
}

extension SurveyOptions {
    private enum Key {
        static let autoIDCluster = "AutoIDCluster"
        static let autoIDTeam = "AutoIDTeam"
        static let autoIDRecord = "AutoIDRecord"
        static let autoIDHousehold = "AutoIDHousehold"
        static let ageGroups = "AgeGroups"
        static let standardsMinZ = "StdMinZBounds"
        static let standardsMaxZ = "StdMaxZBounds"
        static let referenceMinZ = "RefMinZBounds"
        static let referenceMaxZ = "RefMaxZBounds"
        /// Chaves do Anthro II, renomeadas na leitura sem converter o valor.
        static let legacyMinZ = "MinZBounds"
        static let legacyMaxZ = "MaxZBounds"
    }

    /// `SurveyOptions(string xml)`: lê `<O ID>` em qualquer ordem; chave ausente fica no padrão. XML malformado, `<O>` sem
    /// ID, chave repetida (o `Dictionary.Add` do original lança) ou valor ilegível lançam `invalidXML`.
    public init(xml: String) throws {
        let values = try OptionsXMLReader.values(xml)
        self = .default
        func read<T>(_ key: String, _ parse: (String) -> T?, into target: inout T) throws {
            guard let text = values[key] else { return }
            guard let value = parse(text) else { throw SurveyOptionsError.invalidXML("valor ilegível em \(key): \(text)") }
            target = value
        }
        try read(Key.autoIDCluster, Self.bool, into: &autoIDCluster)
        try read(Key.autoIDTeam, Self.bool, into: &autoIDTeam)
        try read(Key.autoIDRecord, Self.bool, into: &autoIDRecord)
        try read(Key.autoIDHousehold, Self.bool, into: &autoIDHousehold)
        try read(Key.ageGroups, Self.integers, into: &ageGroupBoundaries)
        try read(Key.standardsMinZ, Self.decimals, into: &standardsMinZ)
        try read(Key.standardsMaxZ, Self.decimals, into: &standardsMaxZ)
        try read(Key.referenceMinZ, Self.decimals, into: &referenceMinZ)
        try read(Key.referenceMaxZ, Self.decimals, into: &referenceMaxZ)
    }

    /// `GetXML` com as nove chaves sempre, em ordem fixa; booleanos `True`/`False`, listas com `|`, decimais com ponto.
    public func xml() -> String {
        func bool(_ value: Bool) -> String { value ? "True" : "False" }
        func decimals(_ values: [Decimal]) -> String { values.map { "\($0)" }.joined(separator: "|") }
        let entries: [(String, String)] = [
            (Key.autoIDCluster, bool(autoIDCluster)), (Key.autoIDTeam, bool(autoIDTeam)),
            (Key.autoIDRecord, bool(autoIDRecord)), (Key.autoIDHousehold, bool(autoIDHousehold)),
            (Key.ageGroups, ageGroupBoundaries.map(String.init).joined(separator: "|")),
            (Key.standardsMinZ, decimals(standardsMinZ)), (Key.standardsMaxZ, decimals(standardsMaxZ)),
            (Key.referenceMinZ, decimals(referenceMinZ)), (Key.referenceMaxZ, decimals(referenceMaxZ)),
        ]
        return "<Opt>" + entries.map { "<O ID=\"\($0.0)\">\($0.1)</O>" }.joined() + "</Opt>"
    }

    /// Limites mínimo e máximo do indicador na faixa; `nil` se a faixa não for padrões nem referência ou se a lista for
    /// curta (no original, índice fora da lista).
    public func zBounds(_ indicator: Indicator, range: AgeRange) -> (min: Decimal, max: Decimal)? {
        let lists: ([Decimal], [Decimal])
        switch range {
        case .standards: lists = (standardsMinZ, standardsMaxZ)
        case .reference: lists = (referenceMinZ, referenceMaxZ)
        case .unknown, .offLimits: return nil
        }
        let index = indicator.rawValue
        guard lists.0.indices.contains(index), lists.1.indices.contains(index) else { return nil }
        return (lists.0[index], lists.1[index])
    }

    // MARK: Leitura dos valores

    /// `bool.Parse`: "True" ou "False" sem diferenciar maiúsculas, com espaços nas pontas.
    private static func bool(_ text: String) -> Bool? {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true": true
        case "false": false
        default: nil
        }
    }

    private static func integers(_ text: String) -> [Int]? {
        let parts = text.split(separator: "|", omittingEmptySubsequences: false)
            .map { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return parts.contains(nil) ? nil : parts.compactMap { $0 }
    }

    /// Aceita vírgula ou ponto decimal (desvio D11: o original lê na cultura do Windows).
    private static func decimals(_ text: String) -> [Decimal]? {
        let parts = text.split(separator: "|", omittingEmptySubsequences: false).map { part -> Decimal? in
            let normalized = part.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
            guard normalized.range(of: #"^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil else {
                return nil
            }
            return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
        }
        return parts.contains(nil) ? nil : parts.compactMap { $0 }
    }
}

public enum SurveyOptionsError: Error, Equatable {
    case invalidXML(String)
}

/// Leitor das chaves `<O ID="...">valor</O>` em qualquer nível, como `GetElementsByTagName("O")`.
private final class OptionsXMLReader: NSObject, XMLParserDelegate {
    private var values: [String: String] = [:]
    private var currentID: String?
    private var currentText = ""
    private var failure: String?

    static func values(_ xml: String) throws -> [String: String] {
        let reader = OptionsXMLReader()
        let parser = XMLParser(data: Data(xml.utf8))
        parser.delegate = reader
        guard parser.parse(), reader.failure == nil else {
            throw SurveyOptionsError.invalidXML(reader.failure ?? parser.parserError.map { "\($0)" } ?? "XML inválido")
        }
        return reader.values
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        guard elementName == "O" else { return }
        guard let id = attributes["ID"] else {
            fail(parser, "elemento O sem ID")
            return
        }
        switch id {
        case "MinZBounds": currentID = "StdMinZBounds"
        case "MaxZBounds": currentID = "StdMaxZBounds"
        default: currentID = id
        }
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentID != nil { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        guard elementName == "O", let id = currentID else { return }
        currentID = nil
        guard values[id] == nil else {
            fail(parser, "chave repetida: \(id)")
            return
        }
        values[id] = currentText
    }

    private func fail(_ parser: XMLParser, _ message: String) {
        failure = failure ?? message
        parser.abortParsing()
    }
}
