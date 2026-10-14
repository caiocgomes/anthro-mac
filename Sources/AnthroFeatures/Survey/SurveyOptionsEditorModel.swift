import AnthroCore
import Foundation
import Observation

public enum SurveyOptionsEditorError: Error, Equatable {
    case tooFewAgeGroups
    case inconsistentAgeGroups
    case invalidZBounds
}

/// Editor das opções do inquérito (`NSOptionsDialog`, design D10): lista de faixas com limite inferior editável e o
/// superior derivado, limites de z como texto, e nada muda no inquérito antes de `apply()` (desvio D11).
@MainActor
@Observable
public final class SurveyOptionsEditorModel {
    public var autoIDCluster: Bool = false
    public var autoIDTeam: Bool = false
    public var autoIDRecord: Bool = false
    public var autoIDHousehold: Bool = false
    public private(set) var lowerBounds: [Int] = []
    public var lastUpperBound: Int = 0

    /// Limite de z por indicador, faixa (padrões ou referência) e lado.
    private struct BoundKey: Hashable {
        let indicator: Indicator
        let isReference: Bool
        let isMax: Bool
    }

    private var bounds: [BoundKey: Decimal] = [:]
    /// Avaliação do último texto digitado em cada limite; ausente equivale a valor válido.
    private var outcomes: [BoundKey: MeasurementInput.Outcome] = [:]

    static let maxAgeGroups = 21
    static let maxMonths = 228
    static let zRange: ClosedRange<Decimal> = -99...99

    public init(options: SurveyOptions) {
        load(options)
    }

    public var ageGroups: [AgeGroup] {
        AgeGroups.groups(fromBoundaries: lowerBounds + [lastUpperBound])
    }

    public func setLowerBound(_ value: Int, at index: Int) {
        guard lowerBounds.indices.contains(index) else { return }
        lowerBounds[index] = value
    }

    /// Nova faixa no fim, começando um mês depois da última; sem efeito com 21 faixas (os 42 campos do original).
    public func addAgeGroup() {
        guard lowerBounds.count < Self.maxAgeGroups else { return }
        lowerBounds.append(min((lowerBounds.last ?? -1) + 1, Self.maxMonths))
    }

    /// Remove a faixa; a anterior passa a ir até o limite inferior da seguinte menos 1.
    public func removeAgeGroup(at index: Int) {
        guard lowerBounds.indices.contains(index) else { return }
        lowerBounds.remove(at: index)
    }

    public func zBound(_ indicator: Indicator, range: AgeRange, isMax: Bool) -> Decimal {
        bounds[key(indicator, range, isMax)] ?? 0
    }

    /// Valor válido passa por `CheckZRanges` (máximo abaixo do mínimo sobe ao mínimo; mínimo acima do máximo desce ao
    /// máximo); vazio, inválido ou fora de -99 a 99 mantém o limite vigente e bloqueia `apply()`.
    public func setZBound(text: String, indicator: Indicator, range: AgeRange, isMax: Bool) {
        let key = key(indicator, range, isMax)
        let outcome = MeasurementInput.evaluate(text, range: Self.zRange, places: 1)
        guard case .value(var value) = outcome else {
            outcomes[key] = outcome
            return
        }
        let other = bounds[BoundKey(indicator: indicator, isReference: key.isReference, isMax: !isMax)] ?? value
        if isMax, value < other { value = other }
        if !isMax, value > other { value = other }
        bounds[key] = value
        outcomes[key] = .value(value)
    }

    public func zBoundOutcome(_ indicator: Indicator, range: AgeRange, isMax: Bool) -> MeasurementInput.Outcome {
        let key = key(indicator, range, isMax)
        return outcomes[key] ?? .value(bounds[key] ?? 0)
    }

    /// `SurveyOptions.ResetToDefault`: atribuição automática, faixas e limites de z.
    public func resetToDefaults() {
        load(.default)
    }

    /// `CheckGroups` e as mensagens do original: de 2 a 21 faixas, inferiores estritamente crescentes entre 0 e 228 e
    /// último superior entre o último inferior e 228; depois, todos os limites de z legíveis.
    public func apply() throws -> SurveyOptions {
        guard lowerBounds.count >= 2 else { throw SurveyOptionsEditorError.tooFewAgeGroups }
        let increasing = zip(lowerBounds, lowerBounds.dropFirst()).allSatisfy { $0 < $1 }
        guard lowerBounds.count <= Self.maxAgeGroups, increasing,
              let first = lowerBounds.first, let last = lowerBounds.last,
              first >= 0, last <= Self.maxMonths, lastUpperBound >= last, lastUpperBound <= Self.maxMonths
        else { throw SurveyOptionsEditorError.inconsistentAgeGroups }
        let allValid = outcomes.values.allSatisfy { if case .value = $0 { true } else { false } }
        guard allValid else { throw SurveyOptionsEditorError.invalidZBounds }
        var options = SurveyOptions.default
        options.autoIDCluster = autoIDCluster
        options.autoIDTeam = autoIDTeam
        options.autoIDRecord = autoIDRecord
        options.autoIDHousehold = autoIDHousehold
        options.ageGroupBoundaries = lowerBounds + [lastUpperBound]
        options.standardsMinZ = list(isReference: false, isMax: false)
        options.standardsMaxZ = list(isReference: false, isMax: true)
        options.referenceMinZ = list(isReference: true, isMax: false)
        options.referenceMaxZ = list(isReference: true, isMax: true)
        return options
    }

    // MARK: Privado

    private func load(_ options: SurveyOptions) {
        autoIDCluster = options.autoIDCluster
        autoIDTeam = options.autoIDTeam
        autoIDRecord = options.autoIDRecord
        autoIDHousehold = options.autoIDHousehold
        lowerBounds = Array(options.ageGroupBoundaries.dropLast())
        lastUpperBound = options.ageGroupBoundaries.last ?? Self.maxMonths
        bounds = [:]
        outcomes = [:]
        let lists: [(Bool, Bool, [Decimal], [Decimal])] = [
            (false, false, options.standardsMinZ, SurveyOptions.default.standardsMinZ),
            (false, true, options.standardsMaxZ, SurveyOptions.default.standardsMaxZ),
            (true, false, options.referenceMinZ, SurveyOptions.default.referenceMinZ),
            (true, true, options.referenceMaxZ, SurveyOptions.default.referenceMaxZ),
        ]
        for (isReference, isMax, values, defaults) in lists {
            for indicator in Indicator.allCases {
                let index = indicator.rawValue
                bounds[BoundKey(indicator: indicator, isReference: isReference, isMax: isMax)] =
                    values.indices.contains(index) ? values[index] : defaults[index]
            }
        }
    }

    private func key(_ indicator: Indicator, _ range: AgeRange, _ isMax: Bool) -> BoundKey {
        BoundKey(indicator: indicator, isReference: range == .reference, isMax: isMax)
    }

    private func list(isReference: Bool, isMax: Bool) -> [Decimal] {
        Indicator.allCases.map { bounds[BoundKey(indicator: $0, isReference: isReference, isMax: isMax)] ?? 0 }
    }
}
