import AnthroFeatures
import AppKit
import UniformTypeIdentifiers

/// Painel "Salvar como" para a cópia do banco. O painel já pede confirmação para substituir arquivo.
@MainActor
enum DatabaseExporter {
    static func run(store: StoreController) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = L10n.Store.defaultExportName
        panel.allowedContentTypes = [UTType(filenameExtension: "sqlite") ?? .data]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let alert = NSAlert()
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try store.exportCopy(to: url)
            alert.messageText = L10n.Store.exportDone
            alert.informativeText = url.path
        } catch {
            alert.alertStyle = .warning
            alert.messageText = L10n.Store.exportFailed
            alert.informativeText = String(describing: error)
        }
        alert.runModal()
    }
}
