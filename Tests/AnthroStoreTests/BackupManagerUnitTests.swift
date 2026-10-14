import AnthroStore
import Foundation
import Testing

/// Laço interno de `BackupManager` (task 2.4).
@Suite("BackupManager: unidades")
struct BackupManagerUnitTests {
    @Test func listagemIgnoraArquivosAuxiliares() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["anthroplus-20261002-000000.sqlite", "anthroplus-20261001-000000.sqlite",
                     "anthroplus-20261001-000000.sqlite-wal", "anthroplus-20261001-000000.sqlite-shm", "notas.txt"] {
            try Data().write(to: dir.appendingPathComponent(name))
        }
        #expect(BackupManager.backups(in: dir).map(\.lastPathComponent) == [
            "anthroplus-20261001-000000.sqlite",
            "anthroplus-20261002-000000.sqlite",
        ])
    }
}
