import AnthroCore
import Foundation
import Observation

/// Calculadora antropométrica, port de `ACMain` (design D1 a D5).
@MainActor
@Observable
public final class CalculatorModel {
    public private(set) var dateOfBirth: Date
    public private(set) var dateOfVisit: Date
    public private(set) var isApproximateBirthDate: Bool = false
    public private(set) var sex: Sex = .girl
    public private(set) var weight: Decimal? = 20
    public private(set) var lengthOrHeight: Decimal? = 115
    public private(set) var measuredRecumbent: Bool = true
    public private(set) var hasOedema: Bool = false
    public private(set) var result: AnthropometricResult
    public private(set) var weightIssue: MeasurementInput.Outcome? = nil
    public private(set) var lengthOrHeightIssue: MeasurementInput.Outcome? = nil

    @ObservationIgnored private let engine: AnthroEngine
    @ObservationIgnored private let tables: GrowthReferenceTables
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let randomDay: (Range<Int>) -> Int

    private static let weightRange = InputLimits.minWeight...InputLimits.maxWeight
    private static let lengthOrHeightRange = InputLimits.minLengthOrHeight...InputLimits.maxLengthOrHeight

    /// `ACMain()` e `ACMain_Load`: deitado marcado e logo forçado para em pé por `RefreshAge` aos 6 anos.
    public init(engine: AnthroEngine, tables: GrowthReferenceTables, settings: AppSettings, today: Date,
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        self.engine = engine
        self.tables = tables
        self.settings = settings
        self.randomDay = randomDay
        dateOfVisit = today
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -6, to: today) ?? today
        result = engine.result(ageInDays: nil, ageInMonths: nil, sex: nil, weight: nil, lengthOrHeight: nil,
                               measuredRecumbent: false, hasOedema: false)
        refresh()
    }

    public var ageText: String {
        guard let months = ageInMonths else { return "" }
        // Parte inteira dos meses, como `(int)ageInMonths` de `RefreshAge`.
        return AgeText.localized(months: NSDecimalNumber(decimal: MeasurementInput.truncate(months, places: 0)).intValue)
    }

    /// `RefreshAge`: a escolha deitado ou em pé só existe abaixo de 11 meses.
    public var isMeasurementChoiceEnabled: Bool {
        guard let months = ageInMonths else { return false }
        return months < 11
    }

    /// `UpdateIndicators`: IMC sobre a medida ajustada, arredondado a 1 casa; "N/D" com edema ou campo vazio.
    public var bmiText: String {
        guard !hasOedema, let weight, let lengthOrHeight, let days = ageInDays else { return L10n.notAvailable }
        let adjusted = Anthropometry.adjustedLengthOrHeight(ageInDays: days, value: lengthOrHeight,
                                                           measuredRecumbent: measuredRecumbent).value
        let bmi = Anthropometry.exactBMI(weight: weight, lengthOrHeight: adjusted)
        return ClinicalFormat.string(ClinicalRounding.round(bmi, places: 1), places: 1)
    }

    public var rows: [IndicatorPanelRow] {
        IndicatorPanel.rows(for: result)
    }

    /// `dtpDateOfBirth_ValueChanged`: com data aproximada desfaz a troca de dia e sorteia na troca de mês;
    /// nunca passa da visita.
    public func setDateOfBirth(_ date: Date) {
        dateOfBirth = ApproximateBirthDate.adjusted(previous: dateOfBirth, proposed: date, isApprox: isApproximateBirthDate,
                                                    upperBound: dateOfVisit, randomDay: randomDay)
        refresh()
    }

    /// `dtpDateOfVisit_ValueChanged`: visita antes do nascimento puxa o nascimento.
    public func setDateOfVisit(_ date: Date) {
        dateOfVisit = date
        if Self.day(dateOfBirth) > Self.day(dateOfVisit) {
            dateOfBirth = dateOfVisit
        }
        refresh()
    }

    /// `cbDateIsApprox_CheckStateChanged`: marcar sorteia o dia e limita pela visita.
    public func setApproximateBirthDate(_ isOn: Bool) {
        isApproximateBirthDate = isOn
        if isOn {
            let randomized = ApproximateBirthDate.randomized(dateOfBirth, randomDay: randomDay)
            dateOfBirth = Self.day(randomized) > Self.day(dateOfVisit) ? dateOfVisit : randomized
        }
        refresh()
    }

    public func setSex(_ sex: Sex) {
        self.sex = sex
        refresh()
    }

    public func setWeightText(_ text: String) {
        let outcome = MeasurementInput.evaluate(text, range: Self.weightRange)
        weight = outcome.value
        weightIssue = outcome.issueMessage == nil ? nil : outcome
        refresh()
    }

    public func setLengthOrHeightText(_ text: String) {
        let outcome = MeasurementInput.evaluate(text, range: Self.lengthOrHeightRange)
        lengthOrHeight = outcome.value
        lengthOrHeightIssue = outcome.issueMessage == nil ? nil : outcome
        refresh()
    }

    /// Ignorado com a escolha desabilitada, como os botões desabilitados de `ACMain`.
    public func setMeasuredRecumbent(_ isOn: Bool) {
        guard isMeasurementChoiceEnabled else { return }
        measuredRecumbent = isOn
        refresh()
    }

    public func setHasOedema(_ isOn: Bool) {
        hasOedema = isOn
        refresh()
    }

    /// `FormX.PreFilterMessage`: próximo campo habilitado na ordem de tabulação, voltando ao primeiro;
    /// `nil` com `UseEnterForNextControl` desligado.
    public func nextFocus(after field: CalculatorField) -> CalculatorField? {
        guard settings.useEnterForNextControl else { return nil }
        let order = CalculatorField.allCases
        guard let start = order.firstIndex(of: field) else { return nil }
        for offset in 1...order.count {
            let candidate = order[(start + offset) % order.count]
            if candidate != .measurement || isMeasurementChoiceEnabled { return candidate }
        }
        return nil
    }

    /// `indicatorDisplayPanel_GraphButtonClicked*`: um resultado, índice 0.
    public func makeChart(for indicator: Indicator) -> GrowthChartModel {
        GrowthChartModel(results: [result], currentIndex: 0, indicator: indicator, tables: tables)
    }

    // MARK: Recálculo

    private var ageInDays: Int? {
        try? AgeMath.ageInDays(birth: dateOfBirth, visit: dateOfVisit)
    }

    private var ageInMonths: Decimal? {
        ageInDays.map(AgeMath.daysToMonths)
    }

    /// `RefreshAge` seguido de `UpdateIndicators`.
    private func refresh() {
        if !isMeasurementChoiceEnabled {
            measuredRecumbent = false
        }
        let empty = engine.result(ageInDays: nil, ageInMonths: nil, sex: sex, weight: weight, lengthOrHeight: lengthOrHeight,
                                  measuredRecumbent: measuredRecumbent, hasOedema: hasOedema)
        result = (try? engine.result(dateOfBirth: dateOfBirth, dateOfVisit: dateOfVisit, sex: sex, weight: weight,
                                     lengthOrHeight: lengthOrHeight, measuredRecumbent: measuredRecumbent,
                                     hasOedema: hasOedema)) ?? empty
    }

    private static func day(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
