import AnthroFeatures
import SwiftUI

/// `NSFilterDialog`: coluna, condição e um ou dois valores.
struct SurveyFilterSheet: View {
    let columns: [SurveyTableColumn]
    let onApply: (SurveyFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var column: SurveyTableColumn?
    @State private var condition: FilterCondition = .equal
    @State private var value1 = ""
    @State private var value2 = ""

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Picker(L10n.Survey.Filter.column, selection: $column) {
                    ForEach(columns, id: \.self) { Text($0.title).tag(Optional($0)) }
                }
                Picker(L10n.Survey.Filter.condition, selection: $condition) {
                    ForEach(FilterCondition.allCases, id: \.self) { Text($0.symbol).tag($0) }
                }
                TextField(L10n.Survey.Filter.value, text: $value1)
                if condition == .range {
                    TextField(L10n.Survey.Filter.upTo, text: $value2)
                }
                Text(L10n.Survey.Filter.hint).font(.caption).foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button(L10n.Survey.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.Survey.Filter.apply) {
                    if let column {
                        onApply(SurveyFilter(column: column, condition: condition, value1: value1,
                                             value2: condition == .range ? value2 : ""))
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(column == nil)
            }
            .padding(16)
        }
        .frame(width: 420)
        .navigationTitle(L10n.Survey.Filter.title)
        .onAppear { column = column ?? columns.first }
    }
}
