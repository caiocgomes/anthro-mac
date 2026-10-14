import Foundation

/// Backups automáticos do banco (design D5).
public enum BackupManager {
    public static func backupOnLaunch(databaseURL: URL, backupsDirectory: URL, keep: Int = 10, now: Date) throws -> URL? {
        URL(fileURLWithPath: "/dev/null")
    }

    public static func backups(in directory: URL) -> [URL] {
        []
    }

    public static func restoreLatest(from directory: URL, to databaseURL: URL) throws -> URL {
        URL(fileURLWithPath: "/dev/null")
    }
}
