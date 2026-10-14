import Foundation

public enum ChartDisplayMode: Int, CaseIterable, Sendable {
    case zScore
    case percentile

    public var title: String {
        ""
    }
}

public enum CurveStyle: Sendable {
    case sd3
    case sd2
    case sd1
    case median
}

public enum GuideStyle: Sendable {
    case current
    case other
}

public struct ChartXY: Sendable, Equatable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct ChartSeries: Sendable, Equatable, Identifiable {
    public let id: Int
    public let label: String
    public let style: CurveStyle
    public let points: [ChartXY]

    public init(id: Int, label: String, style: CurveStyle, points: [ChartXY]) {
        self.id = id
        self.label = label
        self.style = style
        self.points = points
    }
}

public struct MeasurementPoint: Sendable, Equatable {
    public let resultIndex: Int
    public let x: Double
    public let y: Double
    public let guideStyle: GuideStyle

    public init(resultIndex: Int, x: Double, y: Double, guideStyle: GuideStyle) {
        self.resultIndex = resultIndex
        self.x = x
        self.y = y
        self.guideStyle = guideStyle
    }
}

public struct TransitionMarker: Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let leftLabel: String
    public let leftX: Double
    public let rightLabel: String
    public let rightX: Double

    public init(x: Double, y: Double, leftLabel: String, leftX: Double, rightLabel: String, rightX: Double) {
        self.x = x
        self.y = y
        self.leftLabel = leftLabel
        self.leftX = leftX
        self.rightLabel = rightLabel
        self.rightX = rightX
    }
}
