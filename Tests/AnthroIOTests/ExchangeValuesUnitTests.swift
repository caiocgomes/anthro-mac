import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("individual-data-exchange: resultados e valores adicionais (unitários)")
struct ExchangeValuesUnitTests {
    @Test func visitBeforeBirthOrWithoutMeasuresHasNoBMI() throws {
        let engine = try AnthroEngine.shared()
        let before = ExchangeVisit(date: day("2016-03-14"), weight: 3, height: 50)
        #expect(ExchangeResultsCalculator.results(engine: engine, sex: .girl, dateOfBirth: day("2016-03-15"), visit: before)
            == ExchangeResults(weightForAgeZ: nil, lengthOrHeightForAgeZ: nil, bmiForAgeZ: nil, bmi: nil))
        let noHeight = ExchangeVisit(date: day("2021-04-01"), weight: 18)
        let results = ExchangeResultsCalculator.results(engine: engine, sex: .girl, dateOfBirth: day("2016-03-15"), visit: noHeight)
        #expect(results.bmi == nil)
        #expect(results.weightForAgeZ != nil)
    }

    @Test func additionalValuesFollowGetVariableValueAsString() {
        #expect(AdditionalValueText.text(nil, style: .comma) == "")
        #expect(AdditionalValueText.text(AdditionalDataVariable(identifier: "t", kind: .text("3º ano")), style: .comma) == "3º ano")
        #expect(AdditionalValueText.text(AdditionalDataVariable(identifier: "t", kind: .text(nil)), style: .comma) == "")
        let number = AdditionalDataVariable(identifier: "n", kind: .number(value: d("2.50"), minimum: nil, maximum: nil))
        #expect(AdditionalValueText.text(number, style: .comma) == "2,5")
        #expect(AdditionalValueText.text(number, style: .point) == "2.5")
        let date = AdditionalDataVariable(identifier: "d", kind: .date(day("2021-02-01")))
        #expect(AdditionalValueText.text(date, style: .comma) == "01-02-2021 00:00:00")
        #expect(AdditionalValueText.text(AdditionalDataVariable(identifier: "d", kind: .date(nil)), style: .comma) == "")
    }
}
