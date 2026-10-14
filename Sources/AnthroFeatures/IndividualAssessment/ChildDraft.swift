import AnthroCore
import Foundation

/// Rascunho da ficha da criança em edição (unidade de trabalho, design D3).
public struct ChildDraft: Sendable, Equatable {
    public var id: Int64?
    public var displayID: Int?
    public var firstName: String
    public var lastName: String
    public var sex: Sex?
    public var dateOfBirth: Date
    public var dateOfBirthIsApprox: Bool
    public var notes: String
    public var followUpDate: Date?
    public var followUpInterval: Int?
    public var followUpRefTo: String
    public var motherID: Int64?
    public var fatherID: Int64?
    public var addressID: Int64?
}
