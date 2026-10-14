import AnthroFeatures
import SwiftUI

/// Cria uma Calculadora nova cada vez que o módulo é aberto, como um `ACMain` novo no original.
struct CalculatorHostView: View {
    @State private var model: CalculatorModel?

    init(settings: AppSettings) {
        if let tables = try? GrowthReferenceTables.bundled() {
            _model = State(initialValue: CalculatorModel(engine: AnthroEngine(tables: tables), tables: tables,
                                                         settings: settings, today: Date()))
        }
    }

    var body: some View {
        if let model {
            CalculatorView(model: model)
        } else {
            ContentUnavailableView(L10n.Calculator.tablesUnavailable, systemImage: "exclamationmark.triangle")
        }
    }
}
