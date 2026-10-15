/// A `DataException` do original quando a correção por cluster não encontra cluster nenhum.
public enum AnalysisError: Error, Equatable {
    case noClusterData
}
