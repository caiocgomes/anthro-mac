/// Resultado de `ComboSearch.DoSearch`: resultados demais, nenhum, ou a lista.
public enum LookupSearchOutcome<Item: Sendable & Equatable>: Sendable, Equatable {
    case tooManyResults
    case noResults
    case results([Item])
}
