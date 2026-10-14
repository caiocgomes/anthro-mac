import AnthroFeatures
import Foundation
import Testing

/// Junção entre lista, ficha e editores, apontada pela verificação da add-individual-assessment: cada teste reproduz
/// um caminho em que um dado de pesquisa mudaria ou se perderia sem a usuária querer.
@MainActor
@Suite("Avaliação individual: junção entre lista, ficha e editores")
struct ModelSeamTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try IAFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func detail(today: String = "2026-10-14") -> ChildDetailModel {
        ChildDetailModel(database: db, settings: IAFixtures.settings(), engine: engine,
                         today: { IAFixtures.date(today) }, randomDay: { $0.lowerBound })
    }

    private func list() -> ChildListModel {
        ChildListModel(database: db, settings: IAFixtures.settings())
    }

    // Salvar uma criança arquivada não a devolve à lista ativa.
    @Test func salvarCriancaArquivadaMantemNoArquivo() throws {
        let child = try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana", archived: true)
        let d = detail()
        try d.open(childID: child)
        d.update { $0.firstName = "Ana Maria" }
        try d.save()
        #expect(try IAFixtures.count(db, "children", where: "child_id = \(child) AND is_archived = 1") == 1)
    }

    // No arquivo não se abre a ficha (o original esconde o botão Abrir).
    @Test func arquivoNaoAbreFicha() throws {
        let l = list()
        try l.load()
        #expect(l.canOpen == true)
        try l.showArchive()
        #expect(l.canOpen == false)
    }

    // Salvar uma criança que foi excluída enquanto estava aberta falha e não grava visitas órfãs.
    @Test func salvarCriancaExcluidaFalha() throws {
        let child = try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana")
        let d = detail()
        try d.open(childID: child)
        d.update { $0.firstName = "Bia" }
        try ChildRepository(database: db).delete([child])
        #expect(throws: (any Error).self) { try d.save() }
        #expect(try IAFixtures.count(db, "children") == 0)
        #expect(try IAFixtures.count(db, "visits") == 0)
    }

    // Fechar a ficha deixa o painel vazio, sem alterações pendentes.
    @Test func fecharFichaLimpaRascunho() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        let d = detail()
        try d.open(childID: child)
        d.update { $0.firstName = "Bia" }
        d.close()
        #expect(d.draft == nil)
        #expect(d.visits.isEmpty)
        #expect(d.hasUnsavedChanges == false)
    }

    // A limpeza de órfãos na exclusão preserva a mãe recém-cadastrada que só está ligada ao rascunho aberto.
    @Test func exclusaoPreservaMaeDoRascunho() throws {
        let other = try IAFixtures.insertChild(db, displayID: 1, firstName: "Outra")
        let d = detail()
        d.startNew()
        let mother = try ParentEditorModel(kind: .mother, database: db, editing: nil).save()
        d.update {
            $0.sex = .girl
            $0.motherID = mother.id
        }
        let l = list()
        try l.load(keeping: d.linkedRecords)
        l.checkedIDs = [other]
        try l.deleteChecked(keeping: d.linkedRecords)
        #expect(try IAFixtures.count(db, "mothers") == 1)
        let id = try d.save()
        #expect(try IAFixtures.row(db, "children", where: "child_id = \(id)")?["mother_id"] == .integer(mother.id!))
    }

    // Mãe ou pai novos abrem com nascimento desconhecido, como `Parent()` e `cbDateIsUnknown` do original.
    @Test func paiNovoComecaComNascimentoDesconhecido() throws {
        let father = ParentEditorModel(kind: .father, database: db, editing: nil, today: { IAFixtures.date("2026-10-14") })
        #expect(father.dateOfBirthUnknown == true)
        let saved = try father.save()
        #expect(try IAFixtures.row(db, "fathers", where: "father_id = \(saved.id!)")?["date_of_birth"] == .null)
        let mother = ParentEditorModel(kind: .mother, database: db, editing: nil, today: { IAFixtures.date("2026-10-14") })
        mother.dateOfBirth = IAFixtures.date("1990-05-10")
        #expect(mother.dateOfBirthUnknown == false)
    }

    // Criança nova nasce, por padrão, seis anos antes de hoje, como o `dtpDateOfBirth` do original.
    @Test func criancaNovaNasceSeisAnosAntes() {
        let d = detail(today: "2026-10-14")
        d.startNew()
        #expect(IAFixtures.ymd(d.draft?.dateOfBirth) == "2020-10-14")
    }

    // Data repetida não entra na ficha: continua com 1 visita.
    @Test func dataRepetidaNaoEntraNaFicha() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21")
        let d = detail(today: "2021-09-01")
        try d.open(childID: child)
        let editor = d.makeVisitEditor(editing: nil)
        editor.weightText = "22"
        #expect(throws: VisitValidationError.duplicateDate) { try d.commitVisit(from: editor) }
        #expect(d.visits.count == 1)
    }

    // Peso fora do limite não entra na ficha.
    @Test func pesoForaDoLimiteNaoEntraNaFicha() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        let d = detail(today: "2021-09-01")
        try d.open(childID: child)
        let editor = d.makeVisitEditor(editing: nil)
        editor.weightText = "300"
        editor.lengthOrHeightText = "110"
        #expect(throws: VisitValidationError.invalidMeasurement) { try d.commitVisit(from: editor) }
        #expect(d.visits.isEmpty)
    }
}
