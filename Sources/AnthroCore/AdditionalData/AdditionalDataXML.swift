import Foundation

public enum AdditionalDataXMLError: Error, Equatable {
    case invalid(String)
}

/// Leitura e escrita do XML `<Data><Cat><Txt|Num|Date>` de `AdditionalData` (design D2 a D4).
public enum AdditionalDataXML {
    /// `AdditionalData(string xml)`: seções em qualquer nível, como `GetElementsByTagName("Cat")`; `ID` e `Descr`
    /// obrigatórios, e `Min` e `Max` no número; valor inválido vira `nil`. Texto `nil` ou vazio dá dados sem seções.
    public static func decode(_ xml: String?) throws -> AdditionalData {
        guard let xml, !xml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return AdditionalData() }
        return try AdditionalDataReader.read(xml)
    }

    /// `GetXML` com a forma de `XmlDocument.InnerXml`: sem declaração nem espaços, `Num` com `Min`, `Max`, `ID` e
    /// `Descr` nessa ordem, `Txt` sempre aberto e fechado, elemento vazio autofechado com espaço antes de `/>`.
    public static func encode(_ data: AdditionalData) -> String {
        guard !data.sections.isEmpty else { return "<Data />" }
        var xml = "<Data>"
        for section in data.sections {
            let attributes = "ID=\"\(attribute(section.identifier))\" Descr=\"\(attribute(section.description ?? ""))\""
            guard !section.variables.isEmpty else {
                xml += "<Cat \(attributes) />"
                continue
            }
            xml += "<Cat \(attributes)>"
            for variable in section.variables {
                let names = "ID=\"\(attribute(variable.identifier))\" Descr=\"\(attribute(variable.description ?? ""))\""
                switch variable.kind {
                case .text(let value):
                    xml += "<Txt \(names)>\(text(value ?? ""))</Txt>"
                case .number(let value, let minimum, let maximum):
                    let limits = "Min=\"\(minimum.map(number) ?? "")\" Max=\"\(maximum.map(number) ?? "")\""
                    xml += element("Num", "\(limits) \(names)", value.map(number))
                case .date(let value):
                    xml += element("Date", names, value.map(date))
                }
            }
            xml += "</Cat>"
        }
        return xml + "</Data>"
    }

    // MARK: Formatos

    /// Ponto decimal sempre (desvio D4: o original grava na cultura do Windows).
    static func number(_ value: Decimal) -> String {
        "\(value)"
    }

    /// `dd-MM-yyyy 00:00:00` com o dia de calendário do usuário (D4).
    static func date(_ value: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: value)
        return String(format: "%02d-%02d-%04d 00:00:00", parts.day ?? 1, parts.month ?? 1, parts.year ?? 1)
    }

    /// `ParseNullableDecimal`, aceitando vírgula ou ponto; inválido dá `nil`.
    static func parseNumber(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// `ParseNullableDate` com `ParseExact("dd-MM-yyyy HH:mm:ss")`: forma exata e data existente, ou `nil`; devolve o
    /// meio-dia do dia no calendário do usuário.
    static func parseDate(_ text: String) -> Date? {
        let pattern = #"^([0-9]{2})-([0-9]{2})-([0-9]{4}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$"#
        guard let match = text.range(of: pattern, options: .regularExpression), match == text.startIndex..<text.endIndex
        else { return nil }
        let numbers = text.split(whereSeparator: { $0 == "-" || $0 == " " || $0 == ":" }).compactMap { Int($0) }
        guard numbers.count == 6 else { return nil }
        let (day, month, year, hour, minute, second) = (numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5])
        guard (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second), year >= 1 else { return nil }
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            return nil
        }
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard parts.year == year, parts.month == month, parts.day == day else { return nil }
        return date
    }

    // MARK: Escrita

    private static func element(_ name: String, _ attributes: String, _ value: String?) -> String {
        guard let value else { return "<\(name) \(attributes) />" }
        return "<\(name) \(attributes)>\(text(value))</\(name)>"
    }

    private static func text(_ value: String) -> String {
        xmlCharacters(value).replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func attribute(_ value: String) -> String {
        text(value).replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Só caracteres da produção `Char` do XML 1.0: texto colado com quebra suave do Word (U+000B) ou quebra de página
    /// (U+000C) ganha um espaço, e os demais caracteres de controle saem. Gravados crus, tornariam o XML ilegível para o
    /// próprio app (e para o original), e o registro perderia todas as células adicionais.
    private static func xmlCharacters(_ value: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x9, 0xA, 0xD, 0x20...0xD7FF, 0xE000...0xFFFD, 0x10000...0x10FFFF: scalars.append(scalar)
            case 0xB, 0xC: scalars.append(" ")
            default: break
            }
        }
        return String(scalars)
    }
}

/// Percorre o XML com `XMLParser`: cada `Cat` abre uma seção, e `Txt`, `Num` e `Date` filhos diretos dela viram
/// variáveis; outros elementos são ignorados.
private final class AdditionalDataReader: NSObject, XMLParserDelegate {
    private struct OpenVariable {
        let name: String
        let attributes: [String: String]
        var text = ""
        var hasChildElement = false
    }

    private var sections: [AdditionalDataSection] = []
    /// Nomes dos elementos abertos, para saber se uma variável é filha direta de `Cat`.
    private var stack: [String] = []
    private var openSectionDepths: [Int] = []
    private var openSectionIndices: [Int] = []
    private var variable: OpenVariable?
    private var variableDepth = 0
    private var failure: String?

    static func read(_ xml: String) throws -> AdditionalData {
        let reader = AdditionalDataReader()
        let parser = XMLParser(data: Data(xml.utf8))
        parser.delegate = reader
        guard parser.parse(), reader.failure == nil else {
            let message = reader.failure ?? parser.parserError.map { "\($0)" } ?? "XML inválido"
            throw AdditionalDataXMLError.invalid("The provided XML is invalid: \(message)")
        }
        return AdditionalData(sections: reader.sections)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        if variable != nil {
            variable?.hasChildElement = true
        } else if elementName == "Cat" {
            guard let id = required("ID", in: attributes, of: elementName, parser),
                  let description = required("Descr", in: attributes, of: elementName, parser) else { return }
            sections.append(AdditionalDataSection(identifier: id, description: description.isEmpty ? nil : description))
            openSectionIndices.append(sections.count - 1)
            openSectionDepths.append(stack.count + 1)
        } else if ["Txt", "Num", "Date"].contains(elementName), stack.last == "Cat", !openSectionDepths.isEmpty,
                  openSectionDepths.last == stack.count {
            variable = OpenVariable(name: elementName, attributes: attributes)
            variableDepth = stack.count + 1
        }
        stack.append(elementName)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        variable?.text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        variable?.text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        defer { stack.removeLast() }
        if let open = variable, stack.count == variableDepth {
            variable = nil
            finish(open, parser)
        } else if variable == nil, elementName == "Cat", openSectionDepths.last == stack.count {
            openSectionDepths.removeLast()
            openSectionIndices.removeLast()
        }
    }

    private func finish(_ open: OpenVariable, _ parser: XMLParser) {
        guard let id = required("ID", in: open.attributes, of: open.name, parser),
              let description = required("Descr", in: open.attributes, of: open.name, parser),
              let index = openSectionIndices.last else { return }
        let kind: AdditionalDataVariable.Kind
        switch open.name {
        case "Txt":
            kind = .text(open.text.isEmpty ? nil : open.text)
        case "Num":
            guard let minimum = required("Min", in: open.attributes, of: open.name, parser),
                  let maximum = required("Max", in: open.attributes, of: open.name, parser) else { return }
            let value = open.hasChildElement ? nil : AdditionalDataXML.parseNumber(open.text)
            kind = .number(value: value, minimum: AdditionalDataXML.parseNumber(minimum),
                           maximum: AdditionalDataXML.parseNumber(maximum))
        default:
            kind = .date(open.hasChildElement ? nil : AdditionalDataXML.parseDate(open.text))
        }
        sections[index].variables.append(
            AdditionalDataVariable(identifier: id, description: description.isEmpty ? nil : description, kind: kind))
    }

    private func required(_ name: String, in attributes: [String: String], of element: String,
                          _ parser: XMLParser) -> String? {
        if let value = attributes[name] { return value }
        failure = failure ?? "atributo \(name) ausente em \(element)"
        parser.abortParsing()
        return nil
    }
}
