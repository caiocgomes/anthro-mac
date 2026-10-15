import AnthroCore
import Foundation

/// `Child.ExportChildrenToXML` e `Child.ImportChildrenFromXML`.
public enum ChildXML {
    /// Escrita como o `XmlWriter` do original (`XML.GetWriter`): UTF-8 com BOM, declaração `standalone`, indentação de
    /// dois espaços e CRLF; `Mother`, `Father`, `Address` e `Visits` só quando existem; `AdditionalData` sempre na
    /// visita (design D8); `CreatedBy` fixo e SALB vazio (D9, D16); decimais com ponto (D2).
    public static func data(_ children: [ExchangeChild], includeResults: Bool) -> Data {
        var lines = ["<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"]
        if children.isEmpty {
            lines.append("<Children />")
        } else {
            lines.append("<Children>")
            for child in children {
                lines += childLines(child, includeResults: includeResults)
            }
            lines.append("</Children>")
        }
        return Data([0xEF, 0xBB, 0xBF]) + Data(lines.joined(separator: "\r\n").utf8)
    }

    /// Leitura com as regras de `ImportChildrenFromXML`: qualquer atributo inválido ou estrutura quebrada rejeita o
    /// arquivo inteiro com `invalidStructure` (com o detalhe de linha, elemento e atributo, design D6); visitas fora de
    /// ordem estritamente crescente rejeitam com `invalidFieldValue` (`CheckImportedVisitDates`).
    public static func read(_ data: Data) throws(ImportFailure) -> [ExchangeChild] {
        try readReport(data).children
    }

    /// A leitura de `read(_:)` com os textos cortados nos limites do original (`Child.Notes`, `Address.Place`...),
    /// para avisar a usuária de que o arquivo tinha mais do que o AnthroPlus guarda.
    public static func readReport(_ data: Data) throws(ImportFailure) -> (children: [ExchangeChild], truncated: [ImportFieldError]) {
        let reader = ChildXMLReader()
        let parser = XMLParser(data: data)
        parser.delegate = reader
        let parsed = parser.parse()
        if let failure = reader.failure { throw failure }
        guard parsed else {
            throw .invalidStructure(ImportFailureDetail(line: parser.lineNumber, element: nil, attribute: nil))
        }
        // `XMLParser` não é reentrante: os dados adicionais lidos são decodificados depois da leitura (design D15).
        var children = reader.children
        for pending in reader.pendingAdditionalData {
            guard children.indices.contains(pending.child), children[pending.child].visits.indices.contains(pending.visit) else {
                throw .invalidStructure(ImportFailureDetail(line: pending.line, element: "Visit", attribute: nil))
            }
            do {
                children[pending.child].visits[pending.visit].additionalData = try AdditionalDataXML.decode(pending.text)
            } catch {
                throw .invalidStructure(ImportFailureDetail(line: pending.line, element: "Visit", attribute: "AdditionalData"))
            }
        }
        for child in children where !visitDatesIncrease(child.visits) {
            throw .invalidFieldValue([])
        }
        return (children, reader.truncated)
    }

    /// `CheckImportedVisitDates`: cada visita, na ordem do documento, depois da anterior.
    static func visitDatesIncrease(_ visits: [ExchangeVisit]) -> Bool {
        var previous: Date?
        for visit in visits {
            if let previous, visit.date <= previous { return false }
            previous = visit.date
        }
        return true
    }

    // MARK: Escrita

    private static func childLines(_ child: ExchangeChild, includeResults: Bool) -> [String] {
        let attributes: [(String, String)] = [
            ("DisplayID", FieldWriter.integer(child.displayID)), ("FirstName", FieldWriter.text(child.firstName)),
            ("LastName", FieldWriter.text(child.lastName)), ("DateOfBirth", FieldWriter.date(child.dateOfBirth)),
            ("DateOfBirthIsApprox", FieldWriter.boolean(child.dateOfBirthIsApprox)), ("Sex", FieldWriter.sex(child.sex)),
            ("Notes", FieldWriter.text(child.notes)), ("CreatedBy", ExchangeDefaults.createdBy),
        ]
        var inner: [String] = []
        if let mother = child.mother { inner.append(element("Mother", person(mother), indent: 2)) }
        if let father = child.father { inner.append(element("Father", person(father), indent: 2)) }
        if let address = child.address { inner.append(element("Address", addressAttributes(address), indent: 2)) }
        if !child.visits.isEmpty {
            inner.append("    <Visits>")
            inner += child.visits.map { element("Visit", visitAttributes($0, includeResults: includeResults), indent: 3) }
            inner.append("    </Visits>")
        }
        guard !inner.isEmpty else { return [element("Child", attributes, indent: 1)] }
        return ["  <Child " + attributeText(attributes) + ">"] + inner + ["  </Child>"]
    }

    private static func person(_ person: ExchangePerson) -> [(String, String)] {
        [("FirstName", FieldWriter.text(person.firstName)), ("LastName", FieldWriter.text(person.lastName)),
         ("Height", FieldWriter.decimal(person.height, style: .point)),
         ("Weight", FieldWriter.decimal(person.weight, style: .point)),
         ("DateOfBirth", FieldWriter.date(person.dateOfBirth)),
         ("DateOfBirthIsApprox", FieldWriter.boolean(person.dateOfBirthIsApprox)), ("Notes", FieldWriter.text(person.notes)),
         ("CreatedBy", ExchangeDefaults.createdBy)]
    }

    private static func addressAttributes(_ address: ExchangeAddress) -> [(String, String)] {
        [("StreetInfo", address.streetInfo), ("Place", address.place), ("ZIP", address.zip), ("District", address.district),
         ("Province", address.province), ("State", address.state), ("Country", address.country)]
            .map { ($0.0, FieldWriter.text($0.1)) }
            + [("SALBLevel1", ""), ("SALBLevel2", ""), ("PhoneNumber", FieldWriter.text(address.phoneNumber)),
               ("Email", FieldWriter.text(address.email)), ("CreatedBy", ExchangeDefaults.createdBy)]
    }

    private static func visitAttributes(_ visit: ExchangeVisit, includeResults: Bool) -> [(String, String)] {
        var attributes: [(String, String)] = [
            ("Date", FieldWriter.date(visit.date)), ("Weight", FieldWriter.decimal(visit.weight, style: .point)),
            ("Height", FieldWriter.decimal(visit.height, style: .point)),
            ("IsRecumbent", FieldWriter.measureType(visit.isRecumbent)), ("HasOedema", FieldWriter.boolean(visit.hasOedema)),
            ("Notes", FieldWriter.text(visit.notes)),
            ("AdditionalData", AdditionalDataXML.encode(visit.additionalData ?? AdditionalData())),
            ("CreatedBy", ExchangeDefaults.createdBy),
        ]
        if includeResults {
            let results = visit.results
            attributes += [("WAZ", results?.weightForAgeZ), ("HAZ", results?.lengthOrHeightForAgeZ),
                           ("BAZ", results?.bmiForAgeZ), ("BMI", results?.bmi)]
                .map { ($0.0, FieldWriter.decimal($0.1, style: .point)) }
        }
        return attributes
    }

    private static func element(_ name: String, _ attributes: [(String, String)], indent: Int) -> String {
        String(repeating: "  ", count: indent) + "<\(name) " + attributeText(attributes) + " />"
    }

    private static func attributeText(_ attributes: [(String, String)]) -> String {
        attributes.map { "\($0.0)=\"\(escape($0.1))\"" }.joined(separator: " ")
    }

    /// Escape de atributo do `XmlWriter`: `&`, `<`, `>`, `"` e, para que a releitura não troque por espaço, tabulação e
    /// quebras de linha como referências; caracteres fora do XML 1.0 saem (U+000B e U+000C viram espaço), como no XML de
    /// dados adicionais.
    static func escape(_ value: String) -> String {
        var text = ""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "&": text += "&amp;"
            case "<": text += "&lt;"
            case ">": text += "&gt;"
            case "\"": text += "&quot;"
            case "\t": text += "&#x9;"
            case "\n": text += "&#xA;"
            case "\r": text += "&#xD;"
            case "\u{0B}", "\u{0C}": text += " "
            default:
                switch scalar.value {
                case 0x20...0xD7FF, 0xE000...0xFFFD, 0x10000...0x10FFFF: text.unicodeScalars.append(scalar)
                default: break
                }
            }
        }
        return text
    }
}

/// Lê `Child` com `Mother`, `Father`, `Address` e `Visit` filhos; o primeiro atributo inválido aborta a leitura.
private final class ChildXMLReader: NSObject, XMLParserDelegate {
    private(set) var children: [ExchangeChild] = []
    private(set) var failure: ImportFailure?
    /// Texto de `AdditionalData` de cada visita, para decodificar depois da leitura.
    private(set) var pendingAdditionalData: [(child: Int, visit: Int, text: String, line: Int)] = []
    /// Textos cortados nos limites do original, com a linha e `Elemento.Atributo`.
    private(set) var truncated: [ImportFieldError] = []
    private var current: ExchangeChild?
    private var element = ""
    private var line = 0

    /// Atributo que falhou, para o detalhe da mensagem.
    private struct AttributeError: Error {
        let attribute: String
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        element = elementName
        line = parser.lineNumber
        // `Child` dentro de `Child` e `Mother`, `Father`, `Address` ou `Visit` fora de `Child` são estrutura inválida:
        // aceitá-los perderia dados em silêncio (design D17).
        if elementName == "Child", current != nil {
            fail(parser, element: elementName, attribute: nil)
            return
        }
        if ["Mother", "Father", "Address", "Visit", "Visits"].contains(elementName), current == nil {
            fail(parser, element: elementName, attribute: nil)
            return
        }
        do {
            switch elementName {
            case "Child":
                current = try child(attributes)
            case "Mother":
                current?.mother = try person(attributes)
            case "Father":
                current?.father = try person(attributes)
            case "Address":
                current?.address = try address(attributes)
            case "Visit":
                guard let dateOfBirth = current?.dateOfBirth, let visitIndex = current?.visits.count else { return }
                let (visit, additionalText) = try visit(attributes, dateOfBirth: dateOfBirth)
                current?.visits.append(visit)
                if let additionalText {
                    pendingAdditionalData.append((children.count, visitIndex, additionalText, parser.lineNumber))
                }
            default:
                break
            }
        } catch {
            fail(parser, element: elementName, attribute: error.attribute)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        guard elementName == "Child", let current else { return }
        children.append(current)
        self.current = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if failure == nil {
            failure = .invalidStructure(ImportFailureDetail(line: parser.lineNumber, element: nil, attribute: nil))
        }
    }

    // MARK: Elementos

    private func child(_ a: [String: String]) throws(AttributeError) -> ExchangeChild {
        let displayID = try field("DisplayID") { () throws(FieldParseError) in try FieldParser.unsignedInteger(a["DisplayID"], nullable: true, max: Int(Int32.max)) }
        let firstName = try text(a, "FirstName", nullable: true, limit: 50)
        let lastName = try text(a, "LastName", nullable: true, limit: 50)
        let birth = try field("DateOfBirth") { () throws(FieldParseError) in try FieldParser.date(a["DateOfBirth"], nullable: false) }
        let approx = try field("DateOfBirthIsApprox") { () throws(FieldParseError) in try FieldParser.boolean(a["DateOfBirthIsApprox"], nullable: false) }
        let sex = try field("Sex") { () throws(FieldParseError) in try FieldParser.sex(a["Sex"]) }
        let notes = try text(a, "Notes", nullable: true, limit: 250)
        try discarded(a, "CreatedBy", nullable: true, limit: 20)
        guard let birth else { throw AttributeError(attribute: "DateOfBirth") }
        return ExchangeChild(displayID: displayID, firstName: firstName, lastName: lastName, dateOfBirth: birth,
                             dateOfBirthIsApprox: approx ?? false, sex: sex, notes: notes)
    }

    /// Mãe ou pai: tudo opcional; `DateOfBirthIsApprox` vazio vale falso (design D7).
    private func person(_ a: [String: String]) throws(AttributeError) -> ExchangePerson {
        let firstName = try text(a, "FirstName", nullable: true, limit: 50)
        let lastName = try text(a, "LastName", nullable: true, limit: 50)
        let height = try field("Height") { () throws(FieldParseError) in try FieldParser.decimal(a["Height"], nullable: true, unsigned: true) }
        let weight = try field("Weight") { () throws(FieldParseError) in try FieldParser.decimal(a["Weight"], nullable: true, unsigned: true) }
        let birth = try field("DateOfBirth") { () throws(FieldParseError) in try FieldParser.date(a["DateOfBirth"], nullable: true) }
        let approx = try field("DateOfBirthIsApprox") { () throws(FieldParseError) in try FieldParser.boolean(a["DateOfBirthIsApprox"], nullable: true) }
        let notes = try text(a, "Notes", nullable: true, limit: 250)
        try discarded(a, "CreatedBy", nullable: true, limit: 20)
        return ExchangePerson(firstName: firstName, lastName: lastName, height: height, weight: weight, dateOfBirth: birth,
                              dateOfBirthIsApprox: approx ?? false, notes: notes)
    }

    /// Endereço: textos cortados nos limites do original; SALB e `CreatedBy` lidos e descartados (D9, D16).
    private func address(_ a: [String: String]) throws(AttributeError) -> ExchangeAddress {
        let result = ExchangeAddress(streetInfo: try text(a, "StreetInfo", nullable: true, limit: 50), place: try text(a, "Place", nullable: true, limit: 50),
                                     zip: try text(a, "ZIP", nullable: true, limit: 15), district: try text(a, "District", nullable: true, limit: 50),
                                     province: try text(a, "Province", nullable: true, limit: 50), state: try text(a, "State", nullable: true, limit: 50),
                                     country: try text(a, "Country", nullable: true, limit: 50), phoneNumber: try text(a, "PhoneNumber", nullable: true, limit: 20),
                                     email: try text(a, "Email", nullable: true, limit: 50))
        try discarded(a, "SALBLevel1", nullable: true, limit: 3)
        try discarded(a, "SALBLevel2", nullable: true, limit: 3)
        try discarded(a, "CreatedBy", nullable: true, limit: 20)
        return result
    }

    /// Visita: data não anterior ao nascimento, peso e medida nos limites de `InputLimits` depois do truncamento,
    /// `CreatedBy` obrigatório e descartado; o texto de `AdditionalData` volta à parte, para o codec da change 6 (D15).
    private func visit(_ a: [String: String], dateOfBirth: Date) throws(AttributeError) -> (ExchangeVisit, String?) {
        let date = try field("Date") { () throws(FieldParseError) in try FieldParser.date(a["Date"], nullable: false, notBefore: dateOfBirth) }
        let weight = try field("Weight") { () throws(FieldParseError) in
            try FieldParser.decimal(a["Weight"], nullable: true, unsigned: true, min: InputLimits.minWeight, max: InputLimits.maxWeight)
        }
        let height = try field("Height") { () throws(FieldParseError) in
            try FieldParser.decimal(a["Height"], nullable: true, unsigned: true, min: InputLimits.minLengthOrHeight,
                                    max: InputLimits.maxLengthOrHeight)
        }
        let recumbent = try field("IsRecumbent") { () throws(FieldParseError) in try FieldParser.measureType(a["IsRecumbent"]) }
        let oedema = try field("HasOedema") { () throws(FieldParseError) in try FieldParser.boolean(a["HasOedema"], nullable: false) }
        let notes = try text(a, "Notes", nullable: true, limit: 250)
        let additionalText = try field("AdditionalData") { () throws(FieldParseError) in try FieldParser.text(a["AdditionalData"], nullable: true) }
        try discarded(a, "CreatedBy", nullable: false, limit: 20)
        guard let date else { throw AttributeError(attribute: "Date") }
        return (ExchangeVisit(date: date, weight: weight, height: height, isRecumbent: recumbent,
                              hasOedema: oedema ?? false, notes: notes), additionalText)
    }

    /// Texto com limite do original; o corte é registrado para o aviso da importação.
    private func text(_ a: [String: String], _ name: String, nullable: Bool, limit: Int) throws(AttributeError) -> String? {
        let value = try field(name) { () throws(FieldParseError) in try FieldParser.text(a[name], nullable: nullable, maxLength: limit) }
        if let raw = a[name], raw.count > limit { truncated.append(ImportFieldError(line: line, field: "\(element).\(name)")) }
        return value
    }

    /// Campo lido só para validar como o original (`CreatedBy`, níveis SALB) e descartado: não entra no aviso de corte.
    private func discarded(_ a: [String: String], _ name: String, nullable: Bool, limit: Int) throws(AttributeError) {
        _ = try field(name) { () throws(FieldParseError) in try FieldParser.text(a[name], nullable: nullable, maxLength: limit) }
    }

    private func field<T>(_ name: String, _ parse: () throws(FieldParseError) -> T) throws(AttributeError) -> T {
        do {
            return try parse()
        } catch {
            throw AttributeError(attribute: name)
        }
    }

    private func fail(_ parser: XMLParser, element: String, attribute: String?) {
        failure = failure ?? .invalidStructure(ImportFailureDetail(line: parser.lineNumber, element: element, attribute: attribute))
        parser.abortParsing()
    }
}
