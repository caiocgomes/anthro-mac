import AnthroFeatures
import SwiftUI

extension View {
    /// Conteúdo de folha de edição: enquanto ela está aberta, o app não troca de módulo e não encerra sem avisar, porque o
    /// que foi digitado na folha ainda não é pendência que o guarda do módulo enxergue.
    func editingSheet() -> some View {
        modifier(EditingSheetModifier())
    }
}

private struct EditingSheetModifier: ViewModifier {
    @Environment(AppModel.self) private var app: AppModel?

    func body(content: Content) -> some View {
        content
            .onAppear { app?.sheetPresented() }
            .onDisappear { app?.sheetDismissed() }
    }
}
