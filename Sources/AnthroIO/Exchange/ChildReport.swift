import Foundation

/// `IAMain.GenerateChildReport` em pt-BR (design D12).
public enum ChildReport {
    public static func text(for child: ExchangeChild) -> String { "" }

    public static func data(for child: ExchangeChild) -> Data { Data() }

    public static func suggestedFileName(for child: ExchangeChild) -> String { "" }
}
