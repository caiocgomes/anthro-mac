import AnthroFeatures
import SwiftUI

/// Menus: Sobre, exportação do banco e o menu Módulos com ⌘1 a ⌘3 (design D9).
struct AppCommands: Commands {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(L10n.Menu.about) {
                openWindow(id: "about")
            }
        }
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .importExport) {
            Button(L10n.Menu.exportDatabase) {
                DatabaseExporter.run(store: model.store)
            }
            .disabled(model.store.state != .ready)
        }
        CommandMenu(L10n.Menu.modules) {
            ForEach(AppSection.allCases, id: \.self) { section in
                Button(section.title) {
                    _ = model.handleShortcut(number: section.shortcutNumber)
                }
                .keyboardShortcut(KeyEquivalent(Character(String(section.shortcutNumber))), modifiers: .command)
                .disabled(model.isEditingInSheet)
            }
        }
    }
}
