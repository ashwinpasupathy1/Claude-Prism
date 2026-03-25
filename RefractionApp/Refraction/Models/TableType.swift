// TableType.swift — Data table types that constrain which chart types are valid.
// Matches GraphPad Prism's table types exactly, plus additional types.

import Foundation

enum TableType: String, CaseIterable, Identifiable {
    // Prism standard types (same order as Prism's menu)
    case xy
    case column
    case grouped
    case contingency
    case survival
    case parts
    case multipleVariables
    case nested
    // Additional types beyond Prism
    case twoWay
    case comparison
    case meta

    var id: String { rawValue }

    var label: String {
        switch self {
        case .xy:                 return "XY"
        case .column:             return "Column"
        case .grouped:            return "Grouped"
        case .contingency:        return "Contingency"
        case .survival:           return "Survival"
        case .parts:              return "Parts of whole"
        case .multipleVariables:  return "Multiple variables"
        case .nested:             return "Nested"
        case .twoWay:             return "Two-Way"
        case .comparison:         return "Comparison"
        case .meta:               return "Meta-Analysis"
        }
    }

    var sfSymbol: String {
        switch self {
        case .xy:                 return "chart.xyaxis.line"
        case .column:             return "chart.bar.fill"
        case .grouped:            return "chart.bar.xaxis"
        case .contingency:        return "tablecells"
        case .survival:           return "chart.line.downtrend.xyaxis.circle"
        case .parts:              return "chart.pie"
        case .multipleVariables:  return "rectangle.grid.3x2"
        case .nested:             return "list.bullet.indent"
        case .twoWay:             return "square.grid.2x2"
        case .comparison:         return "arrow.left.arrow.right"
        case .meta:               return "diamond.fill"
        }
    }

    /// Sample data filename (in SampleData bundle resource).
    var sampleDataFilename: String {
        switch self {
        case .xy:                 return "time_series"
        case .column:             return "drug_treatment"
        case .grouped:            return "grouped_data"
        case .contingency:        return "contingency_data"
        case .survival:           return "survival_data"
        case .parts:              return "waterfall_data"
        case .multipleVariables:  return "multiple_variables_data"
        case .nested:             return "nested_data"
        case .twoWay:             return "two_way_anova_data"
        case .comparison:         return "comparison_data"
        case .meta:               return "forest_data"
        }
    }

    /// Default chart type to show when creating a new graph for this table.
    var defaultChartType: ChartType {
        validChartTypes.first!
    }

    /// Chart types valid for this table type.
    var validChartTypes: [ChartType] {
        switch self {
        case .xy:
            return [.scatter, .line, .areaChart, .curveFit, .bubble]
        case .column:
            return [.bar, .box, .violin, .dotPlot, .histogram, .raincloud,
                    .columnStats, .lollipop, .ecdf, .qqPlot]
        case .grouped:
            return [.groupedBar, .stackedBar, .heatmap]
        case .contingency:
            return [.contingency, .chiSquareGof]
        case .survival:
            return [.kaplanMeier]
        case .parts:
            return [.waterfall, .pyramid]
        case .multipleVariables:
            return [.heatmap, .scatter, .bubble]
        case .nested:
            return [.subcolumnScatter, .bar, .box, .dotPlot]
        case .twoWay:
            return [.twoWayAnova]
        case .comparison:
            return [.beforeAfter, .blandAltman, .repeatedMeasures]
        case .meta:
            return [.forestPlot]
        }
    }
}
