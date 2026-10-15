import AnthroCore
import Foundation

/// `Survey.ExportSurveysToXML` e `Survey.ImportSurveysFromXML` (design D13 a D16).
public enum SurveyXML {
    /// Escrita como o `XmlWriter` do original, no mesmo formato do XML da Avaliação individual: UTF-8 com BOM, indentação
    /// de dois espaços e CRLF; `AdditionalDataDef` só com definição, `Records` só com registros, `AdditionalData` sempre
    /// no registro (D13); idade com 10 casas (D14); resultados pela avaliação da change 5 (D15); `CreatedBy` fixo (D16).
    public static func data(_ surveys: [ExchangeSurvey], resultsEngine: AnthroEngine?) -> Data {
        var lines = ["<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"]
        if surveys.isEmpty {
            lines.append("<Surveys />")
        } else {
            lines.append("<Surveys>")
            for survey in surveys {
                lines += surveyLines(survey, resultsEngine: resultsEngine)
            }
            lines.append("</Surveys>")
        }
        return Data([0xEF, 0xBB, 0xBF]) + Data(lines.joined(separator: "\r\n").utf8)
    }

    /// Leitura com as regras de `ImportSurveysFromXML`: atributo inválido, obrigatório ausente ou estrutura quebrada
    /// rejeitam o arquivo inteiro com `invalidStructure`, com linha, elemento e atributo (D13).
    public static func read(_ data: Data) throws(ImportFailure) -> [ExchangeSurvey] {
        try readReport(data).surveys
    }

    /// A leitura de `read(_:)` com os textos cortados nos limites do original (nome e notas do inquérito, nomes e notas
    /// do registro), para avisar a usuária, como o XML da Avaliação individual; `CreatedBy` é descartado e não entra.
    public static func readReport(_ data: Data) throws(ImportFailure) -> (surveys: [ExchangeSurvey], truncated: [ImportFieldError]) {
        let reader = SurveyXMLReader()
        let parser = XMLParser(data: data)
        parser.delegate = reader
        let parsed = parser.parse()
        if let failure = reader.failure { throw failure }
        guard parsed else {
            throw .invalidStructure(ImportFailureDetail(line: parser.lineNumber, element: nil, attribute: nil))
        }
        // `XMLParser` não é reentrante: opções e dados adicionais são decodificados depois da leitura (D18).
        var surveys = reader.surveys
        for pending in reader.pendingSurveys {
            if let options = pending.options {
                do {
                    surveys[pending.survey].survey.options = try SurveyOptions(xml: options)
                } catch {
                    throw .invalidStructure(ImportFailureDetail(line: pending.line, element: "Survey", attribute: "Options"))
                }
            }
            if let definition = surveys[pending.survey].survey.additionalDataDefinitionXML,
               (try? AdditionalDataXML.decode(definition)) == nil {
                throw .invalidStructure(ImportFailureDetail(line: pending.line, element: "Survey", attribute: "AdditionalDataDef"))
            }
        }
        for pending in reader.pendingRecords {
            if let text = surveys[pending.survey].records[pending.record].additionalDataXML,
               (try? AdditionalDataXML.decode(text)) == nil {
                throw .invalidStructure(ImportFailureDetail(line: pending.line, element: "Record", attribute: "AdditionalData"))
            }
        }
        return (surveys, reader.truncated)
    }

    // MARK: Escrita

    private static func surveyLines(_ exchange: ExchangeSurvey, resultsEngine: AnthroEngine?) -> [String] {
        let survey = exchange.survey
        var attributes: [(String, String)] = [("Name", survey.name), ("Notes", FieldWriter.text(survey.notes))]
        if let definition = survey.additionalDataDefinitionXML, !definition.isEmpty {
            attributes.append(("AdditionalDataDef", definition))
        }
        attributes += [("Options", survey.options.xml()), ("CreatedBy", ExchangeDefaults.createdBy)]
        guard !exchange.records.isEmpty else { return [element("Survey", attributes, indent: 1)] }
        return ["  <Survey " + attributeText(attributes) + ">", "    <Records>"]
            + exchange.records.map { element("Record", recordAttributes($0, resultsEngine: resultsEngine), indent: 3) }
            + ["    </Records>", "  </Survey>"]
    }

    private static func recordAttributes(_ record: SurveyRecord, resultsEngine: AnthroEngine?) -> [(String, String)] {
        let additional = record.additionalDataXML.flatMap { $0.isEmpty ? nil : $0 } ?? AdditionalDataXML.encode(AdditionalData())
        var attributes: [(String, String)] = [
            ("Date", FieldWriter.date(record.visitDate)), ("Cluster", FieldWriter.integer(record.cluster)),
            ("Team", FieldWriter.integer(record.team)), ("DisplayID", FieldWriter.integer(record.displayID)),
            ("Household", FieldWriter.integer(record.household)),
            ("WeightingFactor", FieldWriter.decimal(record.weightingFactor, style: .point)),
            ("FirstName", FieldWriter.text(record.firstName)), ("LastName", FieldWriter.text(record.lastName)),
            ("DateOfBirth", FieldWriter.date(record.dateOfBirth)),
            ("DateOfBirthIsApprox", FieldWriter.boolean(record.dateOfBirthIsApprox)),
            ("Age", FieldWriter.decimal(exportedAge(record), style: .point)), ("Sex", FieldWriter.sex(record.sex)),
            ("Weight", FieldWriter.decimal(record.weight, style: .point)),
            ("Height", FieldWriter.decimal(record.lengthOrHeight, style: .point)),
            ("IsRecumbent", FieldWriter.measureType(record.measuredRecumbent)),
            ("HasOedema", FieldWriter.boolean(record.hasOedema ?? false)), ("Notes", FieldWriter.text(record.notes)),
            ("AdditionalData", additional), ("CreatedBy", ExchangeDefaults.createdBy),
        ]
        if let resultsEngine {
            attributes += resultValues(record, engine: resultsEngine).map { ($0.0, FieldWriter.decimal($0.1, style: .point)) }
        }
        return attributes
    }

    /// `GetAgeInMonths` com 10 casas (D14): a idade guardada ou a das datas.
    static func exportedAge(_ record: SurveyRecord) -> Decimal? {
        ClinicalRounding.round(SurveyRecordEvaluation.ageInMonths(record), places: 10)
    }

    /// WAZ, HAZ, BAZ de `Record.AnthroResult` e BMI de `Record.GetBMI` (D15).
    static func resultValues(_ record: SurveyRecord, engine: AnthroEngine) -> [(String, Decimal?)] {
        let result = SurveyRecordEvaluation.result(record, engine: engine)
        return [("WAZ", result.score(.weightForAge).zScore), ("HAZ", result.score(.lengthOrHeightForAge).zScore),
                ("BAZ", result.score(.bmiForAge).zScore), ("BMI", SurveyRecordEvaluation.displayedBMI(record))]
    }

    private static func element(_ name: String, _ attributes: [(String, String)], indent: Int) -> String {
        String(repeating: "  ", count: indent) + "<\(name) " + attributeText(attributes) + " />"
    }

    private static func attributeText(_ attributes: [(String, String)]) -> String {
        attributes.map { "\($0.0)=\"\(ChildXML.escape($0.1))\"" }.joined(separator: " ")
    }
}

/// Lê `Survey` com `Record` filhos; o primeiro atributo inválido aborta a leitura.
private final class SurveyXMLReader: NSObject, XMLParserDelegate {
    private(set) var surveys: [ExchangeSurvey] = []
    private(set) var failure: ImportFailure?
    /// Opções de cada inquérito, para decodificar depois da leitura.
    private(set) var pendingSurveys: [(survey: Int, options: String?, line: Int)] = []
    /// Registros com dados adicionais, para validar depois da leitura.
    private(set) var pendingRecords: [(survey: Int, record: Int, line: Int)] = []
    /// Textos cortados nos limites do original, com a linha e `Elemento.Atributo`.
    private(set) var truncated: [ImportFieldError] = []
    private var current: ExchangeSurvey?
    private var currentOptions: String?
    private var element = ""
    private var line = 0
    private var currentLine = 0
    /// `HC` no primeiro registro do arquivo marca o formato do WHO Anthro, com a idade em dias.
    private var ageInDays: Bool?

    private struct AttributeError: Error {
        let attribute: String
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        element = elementName
        line = parser.lineNumber
        // `Survey` dentro de `Survey` e `Records` ou `Record` fora de `Survey` são estrutura inválida (D18).
        if elementName == "Survey", current != nil {
            fail(parser, element: elementName, attribute: nil)
            return
        }
        if ["Records", "Record"].contains(elementName), current == nil {
            fail(parser, element: elementName, attribute: nil)
            return
        }
        do {
            switch elementName {
            case "Survey":
                let (survey, options) = try survey(attributes)
                current = ExchangeSurvey(survey: survey, records: [])
                currentOptions = options
                currentLine = parser.lineNumber
            case "Record":
                let isWHOAnthro = ageInDays ?? (attributes["HC"] != nil)
                ageInDays = isWHOAnthro
                let record = try record(attributes, ageInDays: isWHOAnthro)
                if record.additionalDataXML != nil, let index = current?.records.count {
                    pendingRecords.append((surveys.count, index, parser.lineNumber))
                }
                current?.records.append(record)
            default:
                break
            }
        } catch {
            fail(parser, element: elementName, attribute: error.attribute)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        guard elementName == "Survey", let current else { return }
        pendingSurveys.append((surveys.count, currentOptions, currentLine))
        surveys.append(current)
        self.current = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if failure == nil {
            failure = .invalidStructure(ImportFailureDetail(line: parser.lineNumber, element: nil, attribute: nil))
        }
    }

    // MARK: Elementos

    /// Nome obrigatório (50), observações (250), definição de dados adicionais e opções guardadas como texto e
    /// decodificadas depois; `CreatedBy` lido e descartado (D16).
    private func survey(_ a: [String: String]) throws(AttributeError) -> (Survey, String?) {
        let name = try text(a, "Name", nullable: false, limit: 50) ?? ""
        // O banco recusa inquérito sem nome (`nameRequired`); recusar aqui aponta o atributo em vez de um erro de gravação.
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AttributeError(attribute: "Name") }
        let notes = try text(a, "Notes", nullable: true, limit: 250)
        let definition = try field("AdditionalDataDef") { () throws(FieldParseError) in
            try FieldParser.text(a["AdditionalDataDef"], nullable: true)
        }
        let options = try field("Options") { () throws(FieldParseError) in try FieldParser.text(a["Options"], nullable: true) }
        _ = try field("CreatedBy") { () throws(FieldParseError) in try FieldParser.text(a["CreatedBy"], nullable: true, maxLength: 20) }
        return (Survey(name: name, notes: notes, additionalDataDefinitionXML: definition), options)
    }

    /// Registro com as regras de `ImportSurveysFromXML`; idade em dias no formato do WHO Anthro; idade descartada
    /// quando há as duas datas, como o setter de `Record.Age` (D18).
    private func record(_ a: [String: String], ageInDays: Bool) throws(AttributeError) -> SurveyRecord {
        let maxInteger = Int(Int32.max)
        let date = try field("Date") { () throws(FieldParseError) in try FieldParser.date(a["Date"], nullable: true) }
        let cluster = try field("Cluster") { () throws(FieldParseError) in
            try FieldParser.unsignedInteger(a["Cluster"], nullable: true, max: maxInteger)
        }
        let team = try field("Team") { () throws(FieldParseError) in try FieldParser.unsignedInteger(a["Team"], nullable: true, max: maxInteger) }
        let displayID = try field("DisplayID") { () throws(FieldParseError) in
            try FieldParser.unsignedInteger(a["DisplayID"], nullable: true, max: maxInteger)
        }
        let household = try field("Household") { () throws(FieldParseError) in
            try FieldParser.unsignedInteger(a["Household"], nullable: true, max: maxInteger)
        }
        let factor = try field("WeightingFactor") { () throws(FieldParseError) in
            try FieldParser.decimal(a["WeightingFactor"], nullable: true, unsigned: true, truncateToPlaces: nil)
        }
        let firstName = try text(a, "FirstName", nullable: true, limit: 50)
        let lastName = try text(a, "LastName", nullable: true, limit: 50)
        let birth = try field("DateOfBirth") { () throws(FieldParseError) in try FieldParser.date(a["DateOfBirth"], nullable: true) }
        let approx = try field("DateOfBirthIsApprox") { () throws(FieldParseError) in
            try FieldParser.boolean(a["DateOfBirthIsApprox"], nullable: false)
        }
        let age = try field("Age") { () throws(FieldParseError) in
            try FieldParser.decimal(a["Age"], nullable: true, unsigned: true, truncateToPlaces: nil)
        }
        let sex = try field("Sex") { () throws(FieldParseError) in try FieldParser.sex(a["Sex"]) }
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
        let additional = try field("AdditionalData") { () throws(FieldParseError) in
            try FieldParser.text(a["AdditionalData"], nullable: true)
        }
        _ = try field("CreatedBy") { () throws(FieldParseError) in try FieldParser.text(a["CreatedBy"], nullable: false, maxLength: 20) }

        var record = SurveyRecord(sex: sex)
        record.visitDate = date
        record.cluster = cluster
        record.team = team
        record.displayID = displayID
        record.household = household
        if let factor { record.weightingFactor = factor }
        record.firstName = firstName
        record.lastName = lastName
        record.dateOfBirth = birth
        record.dateOfBirthIsApprox = approx ?? false
        record.ageInMonths = ageInDays ? age.map { $0 / Decimal(string: "30.4375")! } : age
        if date != nil, birth != nil { record.ageInMonths = nil }
        record.weight = weight
        record.lengthOrHeight = height
        record.measuredRecumbent = recumbent
        record.hasOedema = oedema ?? false
        record.notes = notes
        record.additionalDataXML = additional
        return record
    }

    /// Texto com limite do original; o corte é registrado para o aviso da importação.
    private func text(_ a: [String: String], _ name: String, nullable: Bool, limit: Int) throws(AttributeError) -> String? {
        let value = try field(name) { () throws(FieldParseError) in try FieldParser.text(a[name], nullable: nullable, maxLength: limit) }
        if let raw = a[name], raw.count > limit { truncated.append(ImportFieldError(line: line, field: "\(element).\(name)")) }
        return value
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
