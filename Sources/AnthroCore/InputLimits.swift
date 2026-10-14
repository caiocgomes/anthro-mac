import Foundation

/// Mínimos e máximos dos campos de medida do original (`ACMain`); o motor não os impõe.
public enum InputLimits {
    public static let minWeight: Decimal = 0.9
    public static let maxWeight: Decimal = 275
    public static let minLengthOrHeight: Decimal = 38
    public static let maxLengthOrHeight: Decimal = 230
}
