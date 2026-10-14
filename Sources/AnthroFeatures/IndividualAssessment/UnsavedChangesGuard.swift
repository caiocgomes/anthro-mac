/// Módulo com alterações pendentes que pergunta antes de sair (`IAMain.AskForSave` no `FormClosing` do original):
/// a janela principal consulta o guarda ativo ao trocar de módulo e ao encerrar o app.
@MainActor
public protocol UnsavedChangesGuard: AnyObject {
    var hasUnsavedChanges: Bool { get }
    func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool
}

extension ChildDetailModel: UnsavedChangesGuard {}
