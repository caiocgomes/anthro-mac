import AnthroFeatures
import SwiftUI

/// Banco que falhou na checagem de integridade: oferece restaurar o backup mais recente.
struct CorruptedDatabaseView: View {
    let store: StoreController
    let details: String
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.trianglebadge.exclamationmark")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
            Text(L10n.Store.corruptedTitle)
                .font(.title2.weight(.semibold))
            Text(L10n.Store.corruptedMessage)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
            Text(details)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Button(L10n.Store.restoreLatestBackup) {
                do {
                    try store.restoreLatestBackup()
                } catch StoreError.backupNotFound {
                    errorMessage = L10n.Store.noBackupFound
                } catch {
                    errorMessage = String(describing: error)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
