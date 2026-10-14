import AnthroCore
import Foundation

/// Entrada do gráfico de crescimento a partir da ficha (`GraphDialog(Child, Visit, Indicator)`, design D15).
public struct GrowthChartInput: Sendable, Equatable {
    public let results: [AnthropometricResult]
    public let currentIndex: Int
    public let indicator: Indicator
}

/// Linha da tabela de visitas (`IAMain.dgvVisits_CellValueNeeded`).
public struct VisitRow: Sendable, Equatable {
    public let date: String
    public let weight: String
    public let oedema: String
    public let recumbent: String
    public let lengthOrHeight: String
}
