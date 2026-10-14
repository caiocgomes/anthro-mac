import Foundation

public enum AdditionalDataXMLError: Error, Equatable {
    case invalid(String)
}

/// Leitura e escrita do XML `<Data><Cat><Txt|Num|Date>` de `AdditionalData` (design D2 a D4).
public enum AdditionalDataXML {
    public static func decode(_ xml: String?) throws -> AdditionalData {
        AdditionalData()
    }

    public static func encode(_ data: AdditionalData) -> String {
        ""
    }
}
