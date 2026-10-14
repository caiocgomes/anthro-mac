import AnthroCore
import Foundation

/// `Child.ExportChildrenToDelimitedFile`: 43 colunas na ordem original, resultados opcionais e colunas de dados
/// adicionais do modelo da Avaliação individual; uma linha por visita, e uma linha com a visita vazia para criança sem
/// visitas (design D13 e D14).
public enum ChildDelimitedExport {
    public static let baseColumns = [
        "DisplayID", "FirstName", "LastName", "DateOfBirth", "DateOfBirthIsApprox", "Sex", "ChildNotes", "ChildCreatedBy",
        "MotherFirstName", "MotherLastName", "MotherHeight", "MotherWeight", "MotherDateOfBirth",
        "MotherDateOfBirthIsApprox", "MotherNotes", "MotherCreatedBy",
        "FatherFirstName", "FatherLastName", "FatherHeight", "FatherWeight", "FatherDateOfBirth",
        "FatherDateOfBirthIsApprox", "FatherNotes", "FatherCreatedBy",
        "AddressStreetInfo", "AddressPlace", "AddressZIP", "AddressDistrict", "AddressProvince", "AddressState",
        "AddressCountry", "AddressSALBLevel1", "AddressSALBLevel2", "AddressPhoneNumber", "AddressEmail",
        "AddressCreatedBy",
        "Date", "Weight", "Height", "IsRecumbent", "HasOedema", "Notes", "CreatedBy",
    ]
    public static let resultColumns = ["WAZ", "HAZ", "BAZ", "BMI"]

    public static func data(_ children: [ExchangeChild], additionalDefinition: AdditionalData, includeResults: Bool,
                            format: DelimitedFormat) -> Data {
        let fixed = baseColumns + (includeResults ? resultColumns : [])
        // `GetDataStructure(list)`: as colunas já escritas são chaves proibidas.
        let additional = AdditionalDataColumns.structure(of: additionalDefinition, forbiddenKeys: fixed)
        var rows: [[String]] = []
        for child in children {
            let visits: [ExchangeVisit?] = child.visits.isEmpty ? [nil] : child.visits
            for visit in visits {
                var row = childFields(child) + person(child.mother) + person(child.father) + address(child.address)
                row += visitFields(visit)
                if includeResults {
                    let results = visit?.results
                    row += [results?.weightForAgeZ, results?.lengthOrHeightForAgeZ, results?.bmiForAgeZ, results?.bmi]
                        .map { FieldWriter.decimal($0, style: .comma) }
                }
                row += additional.map { column in
                    AdditionalValueText.text(visit?.additionalData?.variable(section: column.sectionID,
                                                                              variable: column.variableID), style: .comma)
                }
                rows.append(row)
            }
        }
        let text = DelimitedWriter.write(header: fixed + additional.map(\.key), rows: rows, separator: format.separator)
        return DelimitedWriter.utf8WithBOM(text)
    }

    // MARK: Campos

    private static func childFields(_ child: ExchangeChild) -> [String] {
        [FieldWriter.integer(child.displayID), FieldWriter.text(child.firstName), FieldWriter.text(child.lastName),
         FieldWriter.date(child.dateOfBirth), FieldWriter.boolean(child.dateOfBirthIsApprox), FieldWriter.sex(child.sex),
         FieldWriter.text(child.notes), ExchangeDefaults.createdBy]
    }

    /// Mãe ou pai: oito campos, vazios sem a pessoa; `CreatedBy` fixo com ela (design D9).
    private static func person(_ person: ExchangePerson?) -> [String] {
        guard let person else { return Array(repeating: "", count: 8) }
        return [FieldWriter.text(person.firstName), FieldWriter.text(person.lastName),
                FieldWriter.decimal(person.height, style: .comma), FieldWriter.decimal(person.weight, style: .comma),
                FieldWriter.date(person.dateOfBirth), FieldWriter.boolean(person.dateOfBirthIsApprox),
                FieldWriter.text(person.notes), ExchangeDefaults.createdBy]
    }

    /// Endereço: doze campos, com os níveis SALB vazios (design D16).
    private static func address(_ address: ExchangeAddress?) -> [String] {
        guard let address else { return Array(repeating: "", count: 12) }
        return [address.streetInfo, address.place, address.zip, address.district, address.province, address.state,
                address.country].map(FieldWriter.text)
            + ["", "", FieldWriter.text(address.phoneNumber), FieldWriter.text(address.email), ExchangeDefaults.createdBy]
    }

    /// Visita: sete campos, vazios para a criança sem visitas.
    private static func visitFields(_ visit: ExchangeVisit?) -> [String] {
        guard let visit else { return Array(repeating: "", count: 7) }
        return [FieldWriter.date(visit.date), FieldWriter.decimal(visit.weight, style: .comma),
                FieldWriter.decimal(visit.height, style: .comma), FieldWriter.measureType(visit.isRecumbent),
                FieldWriter.boolean(visit.hasOedema), FieldWriter.text(visit.notes), ExchangeDefaults.createdBy]
    }
}
