/// Inquérito nutricional (`Survey` do original).
public struct Survey: Sendable, Equatable, Identifiable {
    public var id: Int64?
    public var name: String
    public var notes: String?
    public var additionalDataDefinitionXML: String?
    public var options: SurveyOptions
    public var isArchived: Bool

    public init(id: Int64? = nil, name: String = "", notes: String? = nil, additionalDataDefinitionXML: String? = nil,
                options: SurveyOptions = .default, isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.notes = notes
        self.additionalDataDefinitionXML = additionalDataDefinitionXML
        self.options = options
        self.isArchived = isArchived
    }
}
