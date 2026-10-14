public enum StoreError: Error, Equatable {
    case sqlite(code: Int32, message: String)
    case corrupted(details: String)
    case migrationFailed(version: Int, message: String)
    case backupNotFound
}
