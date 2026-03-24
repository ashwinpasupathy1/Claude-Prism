// ChartSpec.swift — Public decodable structs matching the Python analysis engine's
// renderer-independent ChartSpec JSON schema.
//
// Extracted from RefractionApp into the RefractionRenderer Swift Package
// so that renderers can be built and tested independently of the app shell.

import Foundation

// MARK: - Top-level response wrapper

/// The JSON envelope returned by POST /render.
public struct RenderResponse: Decodable {
    public let ok: Bool
    public let spec: ChartSpec?
    public let error: String?
}

// MARK: - ChartSpec (renderer-independent)

/// Top-level chart specification decoded from the Python analysis engine.
/// Maps Plotly's `{ data: [...], layout: {...} }` structure into a form
/// suitable for native Core Graphics rendering.
public struct ChartSpec: Decodable {
    public let chartType: String
    public let groups: [GroupData]
    public let style: StyleSpec
    public let axes: AxisSpec
    public let stats: StatsResult?
    public let brackets: [Bracket]
    public let referenceLine: ReferenceLine?

    enum CodingKeys: String, CodingKey {
        case chartType = "chart_type"
        case groups, style, axes, stats, brackets
        case referenceLine = "reference_line"
    }

    /// Decode from Plotly JSON format (`{ data: [...], layout: {...} }`).
    /// Transforms Plotly traces + layout into our renderer-independent model.
    public init(from decoder: Decoder) throws {
        // Try our native format first
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let ct = try? container.decode(String.self, forKey: .chartType) {
            chartType = ct
            groups = (try? container.decode([GroupData].self, forKey: .groups)) ?? []
            style = (try? container.decode(StyleSpec.self, forKey: .style)) ?? StyleSpec()
            axes = (try? container.decode(AxisSpec.self, forKey: .axes)) ?? AxisSpec()
            stats = try? container.decode(StatsResult.self, forKey: .stats)
            brackets = (try? container.decode([Bracket].self, forKey: .brackets)) ?? []
            referenceLine = try? container.decode(ReferenceLine.self, forKey: .referenceLine)
            return
        }

        // Fall back to Plotly JSON format
        let container = try decoder.container(keyedBy: PlotlyCodingKeys.self)
        let traces = (try? container.decode([PlotlyTrace].self, forKey: .data)) ?? []
        let layout = (try? container.decode(PlotlyLayout.self, forKey: .layout)) ?? PlotlyLayout()

        chartType = "bar"
        groups = traces.enumerated().map { idx, trace in
            GroupData(
                name: trace.name ?? "Group \(idx + 1)",
                values: ValuesData(
                    raw: trace.y ?? [],
                    mean: trace.y?.first,
                    sem: trace.errorY?.array?.first,
                    sd: nil,
                    ci95: nil,
                    n: trace.y?.count ?? 0
                ),
                color: trace.markerColor ?? StyleSpec.defaultColors[idx % StyleSpec.defaultColors.count]
            )
        }
        style = StyleSpec(
            colors: traces.compactMap { $0.markerColor },
            showPoints: false,
            showBrackets: true,
            pointSize: 6.0,
            pointAlpha: 0.8,
            barWidth: 0.6,
            errorType: "sem",
            axisStyle: "open"
        )
        axes = AxisSpec(
            title: layout.title?.text ?? "",
            xLabel: layout.xaxis?.title?.text ?? "",
            yLabel: layout.yaxis?.title?.text ?? "",
            xScale: "linear",
            yScale: "linear",
            xRange: nil,
            yRange: nil,
            tickDirection: "out",
            spineWidth: 1.0,
            fontSize: Double(layout.font?.size ?? 12)
        )
        stats = nil
        brackets = []
        referenceLine = nil
    }

    /// Memberwise initializer for programmatic construction.
    public init(
        chartType: String = "bar",
        groups: [GroupData] = [],
        style: StyleSpec = StyleSpec(),
        axes: AxisSpec = AxisSpec(),
        stats: StatsResult? = nil,
        brackets: [Bracket] = [],
        referenceLine: ReferenceLine? = nil
    ) {
        self.chartType = chartType
        self.groups = groups
        self.style = style
        self.axes = axes
        self.stats = stats
        self.brackets = brackets
        self.referenceLine = referenceLine
    }
}

// MARK: - Group and Values

/// One data group (e.g. one bar, one box, one series).
public struct GroupData: Decodable, Identifiable {
    public var id: String { name }
    public let name: String
    public let values: ValuesData
    public let color: String

    public init(name: String, values: ValuesData, color: String) {
        self.name = name
        self.values = values
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case name, values, color
    }
}

/// Numeric values for a single group — raw data plus precomputed summary stats.
public struct ValuesData: Decodable {
    public let raw: [Double]
    public let mean: Double?
    public let sem: Double?
    public let sd: Double?
    public let ci95: Double?
    public let n: Int

    public init(raw: [Double] = [], mean: Double? = nil, sem: Double? = nil,
         sd: Double? = nil, ci95: Double? = nil, n: Int = 0) {
        self.raw = raw
        self.mean = mean
        self.sem = sem
        self.sd = sd
        self.ci95 = ci95
        self.n = n
    }
}

// MARK: - Statistics

/// Result of statistical analysis performed by the Python engine.
public struct StatsResult: Decodable {
    public let testName: String
    public let pValue: Double?
    public let statistic: Double?
    public let comparisons: [Comparison]
    public let normality: NormalityResult?
    public let effectSize: Double?
    public let warning: String?

    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case pValue = "p_value"
        case statistic
        case comparisons
        case normality
        case effectSize = "effect_size"
        case warning
    }
}

/// A single pairwise comparison (e.g. post-hoc test result).
public struct Comparison: Decodable {
    public let group1: String
    public let group2: String
    public let pValue: Double
    public let significant: Bool
    public let label: String

    enum CodingKeys: String, CodingKey {
        case group1 = "group_1"
        case group2 = "group_2"
        case pValue = "p_value"
        case significant, label
    }
}

/// Normality test results for the dataset.
public struct NormalityResult: Decodable {
    public let testName: String
    public let pValue: Double
    public let isNormal: Bool
    public let warning: String?

    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case pValue = "p_value"
        case isNormal = "is_normal"
        case warning
    }
}

/// A significance bracket drawn between two groups.
public struct Bracket: Decodable {
    public let leftIndex: Int
    public let rightIndex: Int
    public let label: String
    public let stackingOrder: Int

    enum CodingKeys: String, CodingKey {
        case leftIndex = "left_index"
        case rightIndex = "right_index"
        case label
        case stackingOrder = "stacking_order"
    }
}

/// Horizontal reference line.
public struct ReferenceLine: Decodable {
    public let y: Double
    public let label: String
}

// MARK: - Style

/// Visual style parameters for the chart.
public struct StyleSpec: Decodable {
    public let colors: [String]
    public let showPoints: Bool
    public let showBrackets: Bool
    public let pointSize: Double
    public let pointAlpha: Double
    public let barWidth: Double
    public let errorType: String
    public let axisStyle: String

    public static let defaultColors = [
        "#E8453C", "#2274A5", "#32936F", "#F18F01", "#A846A0",
        "#6B4226", "#048A81", "#D4AC0D", "#3B1F2B", "#44BBA4",
    ]

    public init(
        colors: [String] = defaultColors,
        showPoints: Bool = false,
        showBrackets: Bool = true,
        pointSize: Double = 6.0,
        pointAlpha: Double = 0.8,
        barWidth: Double = 0.6,
        errorType: String = "sem",
        axisStyle: String = "open"
    ) {
        self.colors = colors
        self.showPoints = showPoints
        self.showBrackets = showBrackets
        self.pointSize = pointSize
        self.pointAlpha = pointAlpha
        self.barWidth = barWidth
        self.errorType = errorType
        self.axisStyle = axisStyle
    }

    enum CodingKeys: String, CodingKey {
        case colors
        case showPoints = "show_points"
        case showBrackets = "show_brackets"
        case pointSize = "point_size"
        case pointAlpha = "point_alpha"
        case barWidth = "bar_width"
        case errorType = "error_type"
        case axisStyle = "axis_style"
    }
}

// MARK: - Axes

/// Axis configuration.
public struct AxisSpec: Decodable {
    public let title: String
    public let xLabel: String
    public let yLabel: String
    public let xScale: String
    public let yScale: String
    public let xRange: [Double]?
    public let yRange: [Double]?
    public let tickDirection: String
    public let spineWidth: Double
    public let fontSize: Double

    public init(
        title: String = "",
        xLabel: String = "",
        yLabel: String = "",
        xScale: String = "linear",
        yScale: String = "linear",
        xRange: [Double]? = nil,
        yRange: [Double]? = nil,
        tickDirection: String = "out",
        spineWidth: Double = 1.0,
        fontSize: Double = 12.0
    ) {
        self.title = title
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.xScale = xScale
        self.yScale = yScale
        self.xRange = xRange
        self.yRange = yRange
        self.tickDirection = tickDirection
        self.spineWidth = spineWidth
        self.fontSize = fontSize
    }

    enum CodingKeys: String, CodingKey {
        case title
        case xLabel = "x_label"
        case yLabel = "y_label"
        case xScale = "x_scale"
        case yScale = "y_scale"
        case xRange = "x_range"
        case yRange = "y_range"
        case tickDirection = "tick_direction"
        case spineWidth = "spine_width"
        case fontSize = "font_size"
    }
}

// MARK: - Plotly JSON intermediate types (for decoding /render responses)

private enum PlotlyCodingKeys: String, CodingKey {
    case data, layout
}

private struct PlotlyTrace: Decodable {
    let x: [AnyCodable]?
    let y: [Double]?
    let name: String?
    let markerColor: String?
    let errorY: PlotlyErrorY?

    enum CodingKeys: String, CodingKey {
        case x, y, name
        case markerColor = "marker_color"
        case errorY = "error_y"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try? container.decode([AnyCodable].self, forKey: .x)
        y = try? container.decode([Double].self, forKey: .y)
        name = try? container.decode(String.self, forKey: .name)
        errorY = try? container.decode(PlotlyErrorY.self, forKey: .errorY)

        if let mc = try? container.decode(String.self, forKey: .markerColor) {
            markerColor = mc
        } else {
            struct Marker: Decodable { let color: String? }
            enum MarkerKey: String, CodingKey { case marker }
            if let markerContainer = try? decoder.container(keyedBy: MarkerKey.self),
               let marker = try? markerContainer.decode(Marker.self, forKey: .marker) {
                markerColor = marker.color
            } else {
                markerColor = nil
            }
        }
    }
}

private struct PlotlyErrorY: Decodable {
    let type: String?
    let array: [Double]?
    let visible: Bool?
}

private struct PlotlyLayout: Decodable {
    let title: PlotlyTitle?
    let xaxis: PlotlyAxis?
    let yaxis: PlotlyAxis?
    let font: PlotlyFont?

    init(title: PlotlyTitle? = nil, xaxis: PlotlyAxis? = nil,
         yaxis: PlotlyAxis? = nil, font: PlotlyFont? = nil) {
        self.title = title
        self.xaxis = xaxis
        self.yaxis = yaxis
        self.font = font
    }
}

private struct PlotlyTitle: Decodable {
    let text: String?
}

private struct PlotlyAxis: Decodable {
    let title: PlotlyTitle?
}

private struct PlotlyFont: Decodable {
    let size: Int?
}

// MARK: - AnyCodable helper

public struct AnyCodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            value = s
        } else if let d = try? container.decode(Double.self) {
            value = d
        } else if let i = try? container.decode(Int.self) {
            value = i
        } else if let b = try? container.decode(Bool.self) {
            value = b
        } else {
            value = ""
        }
    }

    public var stringValue: String {
        if let s = value as? String { return s }
        if let d = value as? Double { return String(d) }
        if let i = value as? Int { return String(i) }
        return String(describing: value)
    }
}
