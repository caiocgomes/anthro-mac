import Foundation
import Observation

/// Abertura do banco com backup, integridade e migração, nesta ordem (design D5).
@MainActor
@Observable
public final class StoreController {
    public enum State: Equatable {
        case closed
        case ready
        case corrupted(String)
        case failed(String)
    }

    public private(set) var state: State = .closed
    public private(set) var database: AnthroDatabase? = nil

    @ObservationIgnored private let directory: URL
    @ObservationIgnored private let now: () -> Date

    public init(directory: URL, now: @escaping () -> Date = Date.init) {
        self.directory = directory
        self.now = now
    }

    private var databaseURL: URL {
        directory.appendingPathComponent("anthroplus.sqlite")
    }

    private var backupsDirectory: URL {
        directory.appendingPathComponent("Backups", isDirectory: true)
    }

    /// Cria o diretório, faz o backup do banco existente e só então abre e migra. Um backup que falha
    /// porque o arquivo não é um banco válido leva a `.corrupted`, sem tocar no arquivo.
    public func openOnLaunch() {
        closeDatabase()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            state = .failed(error.localizedDescription)
            return
        }
        do {
            _ = try BackupManager.backupOnLaunch(
                databaseURL: databaseURL, backupsDirectory: backupsDirectory, keep: 10, now: now()
            )
        } catch let StoreError.sqlite(code, message) where AnthroDatabase.isCorruption(code) {
            state = .corrupted(message)
            return
        } catch {
            state = .failed(String(describing: error))
            return
        }
        openDatabase()
    }

    /// Guarda o arquivo corrompido como `anthroplus.corrupted-AAAAMMDD-HHMMSS.sqlite`, restaura o backup
    /// mais recente e reabre. Sem backup, lança `StoreError.backupNotFound` e não muda o estado.
    public func restoreLatestBackup() throws {
        guard !BackupManager.backups(in: backupsDirectory).isEmpty else {
            throw StoreError.backupNotFound
        }
        closeDatabase()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: databaseURL.path) {
            let corrupted = directory.appendingPathComponent(
                "anthroplus.corrupted-\(BackupManager.timestamp(now())).sqlite"
            )
            try fileManager.moveItem(at: databaseURL, to: corrupted)
        }
        _ = try BackupManager.restoreLatest(from: backupsDirectory, to: databaseURL)
        openDatabase()
        if case .corrupted(let details) = state {
            throw StoreError.corrupted(details: details)
        }
    }

    /// Grava uma cópia consistente do banco aberto, sem sobrescrever arquivo existente.
    public func exportCopy(to url: URL) throws {
        guard let database else {
            throw StoreError.sqlite(code: 21, message: "banco fechado")
        }
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
        }
        try database.backup(to: url)
    }

    private func openDatabase() {
        do {
            database = try AnthroDatabase.open(at: databaseURL)
            state = .ready
        } catch StoreError.corrupted(let details) {
            state = .corrupted(details)
        } catch {
            state = .failed(String(describing: error))
        }
    }

    private func closeDatabase() {
        database?.close()
        database = nil
    }
}
