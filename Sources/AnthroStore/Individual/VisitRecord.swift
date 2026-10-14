import Foundation

/// Visita de uma criança, identificada por criança e data (`Visit` do original, design D2).
public struct VisitRecord: Sendable, Equatable {
    public var childID: Int64?
    public var date: Date
    public var weight: Decimal?
    public var lengthOrHeight: Decimal?
    public var measuredRecumbent: Bool
    public var hasOedema: Bool
    public var notes: String?
    public var additionalDataXML: String?

    public init(childID: Int64? = nil, date: Date, weight: Decimal? = nil, lengthOrHeight: Decimal? = nil,
                measuredRecumbent: Bool = false, hasOedema: Bool = false, notes: String? = nil,
                additionalDataXML: String? = nil) {
        self.childID = childID
        self.date = date
        self.weight = weight
        self.lengthOrHeight = lengthOrHeight
        self.measuredRecumbent = measuredRecumbent
        self.hasOedema = hasOedema
        self.notes = notes
        self.additionalDataXML = additionalDataXML
    }
}
