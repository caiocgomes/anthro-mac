import Foundation

/// `Child.ExportChildrenToXML` e `Child.ImportChildrenFromXML`.
public enum ChildXML {
    public static func data(_ children: [ExchangeChild], includeResults: Bool) -> Data { Data() }

    public static func read(_ data: Data) throws(ImportFailure) -> [ExchangeChild] { [] }
}
