import AnthroCore
import Foundation
import Testing

/// Fronteiras etárias padrão escritas por extenso (`_AGEGROUPS_DEFAULT` do original).
let literalAgeBoundaries = [0, 6, 12, 24, 36, 48, 61, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 228, 228]

/// Opções padrão montadas campo a campo com literais, sem depender de `SurveyOptions.default`.
func literalSurveyOptions() -> SurveyOptions {
    var options = SurveyOptions.default
    options.autoIDCluster = false
    options.autoIDTeam = false
    options.autoIDRecord = true
    options.autoIDHousehold = true
    options.ageGroupBoundaries = literalAgeBoundaries
    options.standardsMinZ = [-6, -6, -5]
    options.standardsMaxZ = [5, 6, 5]
    options.referenceMinZ = [-6, -6, -5]
    options.referenceMaxZ = [5, 6, 5]
    return options
}

/// Confere os nove valores padrão contra literais.
func expectLiteralDefaultOptions(_ options: SurveyOptions, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(options.autoIDCluster == false, sourceLocation: sourceLocation)
    #expect(options.autoIDTeam == false, sourceLocation: sourceLocation)
    #expect(options.autoIDRecord == true, sourceLocation: sourceLocation)
    #expect(options.autoIDHousehold == true, sourceLocation: sourceLocation)
    #expect(options.ageGroupBoundaries == literalAgeBoundaries, sourceLocation: sourceLocation)
    #expect(options.standardsMinZ == [-6, -6, -5], sourceLocation: sourceLocation)
    #expect(options.standardsMaxZ == [5, 6, 5], sourceLocation: sourceLocation)
    #expect(options.referenceMinZ == [-6, -6, -5], sourceLocation: sourceLocation)
    #expect(options.referenceMaxZ == [5, 6, 5], sourceLocation: sourceLocation)
}
