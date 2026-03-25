// ChartType.swift — All 29 chart types with metadata for sidebar grouping.

import Foundation

enum ChartCategory: String, CaseIterable, Identifiable {
    case column = "Column"
    case xy = "XY"
    case grouped = "Grouped"
    case distribution = "Distribution"
    case survival = "Survival"
    case comparison = "Comparison"
    case specialized = "Specialized"
    case statistical = "Statistical"

    var id: String { rawValue }
}

enum ChartType: String, CaseIterable, Identifiable {
    // Column
    case bar
    case box
    case dotPlot = "dot_plot"
    case lollipop
    case columnStats = "column_stats"
    case subcolumnScatter = "subcolumn_scatter"
    case histogram

    // XY
    case scatter
    case line
    case areaChart = "area_chart"
    case curveFit = "curve_fit"
    case bubble

    // Grouped
    case groupedBar = "grouped_bar"
    case stackedBar = "stacked_bar"
    case heatmap

    // Distribution
    case violin
    case raincloud
    case qqPlot = "qq_plot"
    case ecdf

    // Survival
    case kaplanMeier = "kaplan_meier"

    // Comparison
    case beforeAfter = "before_after"
    case blandAltman = "bland_altman"
    case repeatedMeasures = "repeated_measures"

    // Specialized
    case waterfall
    case pyramid
    case forestPlot = "forest_plot"

    // Statistical
    case twoWayAnova = "two_way_anova"
    case contingency
    case chiSquareGof = "chi_square_gof"

    var id: String { rawValue }

    /// The API key sent to the Python server (matches engine keys).
    var key: String { rawValue }

    /// Human-readable label for the sidebar.
    var label: String {
        switch self {
        case .bar:               return "Bar Chart"
        case .box:               return "Box Plot"
        case .dotPlot:           return "Dot Plot"
        case .lollipop:          return "Lollipop"
        case .columnStats:       return "Col Statistics"
        case .subcolumnScatter:  return "Subcolumn"
        case .histogram:         return "Histogram"
        case .scatter:           return "Scatter Plot"
        case .line:              return "Line Graph"
        case .areaChart:         return "Area Chart"
        case .curveFit:          return "Curve Fit"
        case .bubble:            return "Bubble Chart"
        case .groupedBar:        return "Grouped Bar"
        case .stackedBar:        return "Stacked Bar"
        case .heatmap:           return "Heatmap"
        case .violin:            return "Violin Plot"
        case .raincloud:         return "Raincloud"
        case .qqPlot:            return "Q-Q Plot"
        case .ecdf:              return "ECDF"
        case .kaplanMeier:       return "Survival Curve"
        case .beforeAfter:       return "Before / After"
        case .blandAltman:       return "Bland-Altman"
        case .repeatedMeasures:  return "Repeated Meas."
        case .waterfall:         return "Waterfall"
        case .pyramid:           return "Pyramid"
        case .forestPlot:        return "Forest Plot"
        case .twoWayAnova:       return "Two-Way ANOVA"
        case .contingency:       return "Contingency"
        case .chiSquareGof:      return "Chi-Sq GoF"
        }
    }

    /// Sidebar category for grouping.
    var category: ChartCategory {
        switch self {
        case .bar, .box, .dotPlot, .lollipop, .columnStats,
             .subcolumnScatter, .histogram:
            return .column
        case .scatter, .line, .areaChart, .curveFit, .bubble:
            return .xy
        case .groupedBar, .stackedBar, .heatmap:
            return .grouped
        case .violin, .raincloud, .qqPlot, .ecdf:
            return .distribution
        case .kaplanMeier:
            return .survival
        case .beforeAfter, .blandAltman, .repeatedMeasures:
            return .comparison
        case .waterfall, .pyramid, .forestPlot:
            return .specialized
        case .twoWayAnova, .contingency, .chiSquareGof:
            return .statistical
        }
    }

    /// Whether this chart type supports jittered data points overlay.
    var hasPoints: Bool {
        switch self {
        case .bar, .box, .violin, .beforeAfter, .dotPlot,
             .subcolumnScatter, .raincloud:
            return true
        default:
            return false
        }
    }

    /// Whether this chart type supports error bars (SEM/SD/CI95).
    var hasErrorBars: Bool {
        switch self {
        case .bar, .groupedBar, .dotPlot, .lollipop, .columnStats:
            return true
        default:
            return false
        }
    }

    /// Whether this chart type supports statistical tests.
    var hasStats: Bool {
        switch self {
        case .histogram, .heatmap, .waterfall, .pyramid,
             .forestPlot, .curveFit, .areaChart, .ecdf, .qqPlot:
            return false
        default:
            return true
        }
    }

    /// SF Symbol name for the sidebar icon.
    var sfSymbol: String {
        switch self {
        case .bar:               return "chart.bar.fill"
        case .box:               return "square.fill"
        case .dotPlot:           return "circle.grid.3x3"
        case .lollipop:          return "line.3.horizontal.decrease"
        case .columnStats:       return "tablecells"
        case .subcolumnScatter:  return "circle.grid.cross"
        case .histogram:         return "chart.bar.xaxis.ascending"
        case .scatter:           return "circle.grid.cross.fill"
        case .line:              return "chart.xyaxis.line"
        case .areaChart:         return "chart.line.downtrend.xyaxis"
        case .curveFit:          return "point.topleft.down.to.point.bottomright.curvepath"
        case .bubble:            return "circle.circle"
        case .groupedBar:        return "chart.bar.xaxis"
        case .stackedBar:        return "chart.bar.doc.horizontal"
        case .heatmap:           return "square.grid.3x3.fill"
        case .violin:            return "waveform.path"
        case .raincloud:         return "cloud.rain"
        case .qqPlot:            return "arrow.up.right"
        case .ecdf:              return "stairs"
        case .kaplanMeier:       return "chart.line.downtrend.xyaxis.circle"
        case .beforeAfter:       return "arrow.left.arrow.right"
        case .blandAltman:       return "arrow.up.and.down"
        case .repeatedMeasures:  return "point.3.connected.trianglepath.dotted"
        case .waterfall:         return "chart.waterfall.uptrend"
        case .pyramid:           return "triangle.fill"
        case .forestPlot:        return "diamond.fill"
        case .twoWayAnova:       return "square.grid.2x2"
        case .contingency:       return "tablecells.badge.ellipsis"
        case .chiSquareGof:      return "checkmark.square"
        }
    }

    /// Chart types grouped by category for sidebar display.
    static var byCategory: [(category: ChartCategory, types: [ChartType])] {
        ChartCategory.allCases.compactMap { cat in
            let types = ChartType.allCases.filter { $0.category == cat }
            return types.isEmpty ? nil : (category: cat, types: types)
        }
    }
}
