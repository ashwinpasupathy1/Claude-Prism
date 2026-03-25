// Sheet.swift — Individual sheet within a data table (graph, results, info, or data view).

import Foundation
import RefractionRenderer

enum SheetKind: String {
    case dataTable
    case graph
    case results
    case info
}

@Observable
final class Sheet: Identifiable {
    let id: UUID
    var kind: SheetKind
    var label: String

    // Graph sheet properties
    var chartType: ChartType?
    var chartConfig: ChartConfig?
    var chartSpec: ChartSpec?
    var formatSettings: FormatGraphSettings = FormatGraphSettings()
    var formatAxesSettings: FormatAxesSettings = FormatAxesSettings()
    var isLoading: Bool = false

    // Results sheet properties
    var statsResults: StatsResult?

    // Info sheet properties
    var notes: String = ""

    /// Raw JSON string from the engine response (for developer mode).
    var rawJSON: String = ""

    var sfSymbol: String {
        switch kind {
        case .dataTable: return "tablecells"
        case .graph:     return "chart.bar.fill"
        case .results:   return "list.clipboard"
        case .info:      return "info.circle"
        }
    }

    init(
        id: UUID = UUID(),
        kind: SheetKind,
        label: String,
        chartType: ChartType? = nil
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.chartType = chartType
        if kind == .graph {
            self.chartConfig = ChartConfig()
        }
    }

    static func dataSheet() -> Sheet {
        Sheet(kind: .dataTable, label: "Data")
    }

    static func graphSheet(chartType: ChartType) -> Sheet {
        Sheet(kind: .graph, label: chartType.label, chartType: chartType)
    }

    static func resultsSheet(label: String = "Results") -> Sheet {
        Sheet(kind: .results, label: label)
    }

    static func infoSheet() -> Sheet {
        Sheet(kind: .info, label: "Info")
    }
}
