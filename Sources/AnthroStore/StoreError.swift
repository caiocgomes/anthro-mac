public enum StoreError: Error, Equatable {
    case sqlite(code: Int32, message: String)
    case corrupted(details: String)
    case migrationFailed(version: Int, message: String)
    case backupNotFound
    /// Atualização de um registro que não existe mais (por exemplo, criança excluída com a ficha aberta).
    case recordNotFound(table: String, id: Int64)
}
