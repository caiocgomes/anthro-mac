import Foundation

/// Backups automáticos do banco (design D5): `Backups/anthroplus-AAAAMMDD-HHMMSS.sqlite`, em UTC.
public enum BackupManager {
    private static let namePattern = #"^anthroplus-[0-9]{8}-[0-9]{6}\.sqlite$"#

    /// Copia o banco existente para um backup datado e mantém só os `keep` mais recentes.
    /// Sem banco no caminho, devolve `nil` e não cria nada.
    public static func backupOnLaunch(databaseURL: URL, backupsDirectory: URL, keep: Int = 10, now: Date) throws -> URL? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: databaseURL.path) else { return nil }
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        let destination = backupsDirectory.appendingPathComponent("anthroplus-\(timestamp(now)).sqlite")
        if !fileManager.fileExists(atPath: destination.path) {
            do {
                try AnthroDatabase.backupFile(at: databaseURL, to: destination)
            } catch {
                try? fileManager.removeItem(at: destination)
                throw error
            }
        }
        for stale in backups(in: backupsDirectory).dropLast(max(keep, 0)) {
            try fileManager.removeItem(at: stale)
        }
        return destination
    }

    /// Backups do diretório, do mais antigo para o mais recente; ignora `-wal`, `-shm` e outros arquivos.
    public static func backups(in directory: URL) -> [URL] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names
            .filter { $0.range(of: namePattern, options: .regularExpression) != nil }
            .sorted()
            .map { directory.appendingPathComponent($0) }
    }

    /// Copia o backup mais recente sobre `databaseURL` (que deve estar fechado) e devolve o backup usado.
    public static func restoreLatest(from directory: URL, to databaseURL: URL) throws -> URL {
        guard let latest = backups(in: directory).last else { throw StoreError.backupNotFound }
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let path = databaseURL.path + suffix
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(atPath: path)
            }
        }
        try fileManager.copyItem(at: latest, to: databaseURL)
        return latest
    }

    /// `AAAAMMDD-HHMMSS` em UTC.
    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
