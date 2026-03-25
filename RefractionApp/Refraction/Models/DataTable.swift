// DataTable.swift — A data table with its associated sheets (graphs, results, info).
// Each data table has a type that constrains which chart types are valid.

import Foundation

@Observable
final class DataTable: Identifiable {
    let id: UUID
    var label: String
    var tableType: TableType
    var dataFilePath: String?
    var sheets: [Sheet]

    /// Valid chart types for "Add Graph" based on table type.
    var availableChartTypes: [ChartType] {
        tableType.validChartTypes
    }

    /// Whether data has been loaded into this table.
    var hasData: Bool {
        dataFilePath != nil && !dataFilePath!.isEmpty
    }

    init(
        id: UUID = UUID(),
        label: String,
        tableType: TableType,
        dataFilePath: String? = nil,
        sheets: [Sheet]? = nil
    ) {
        self.id = id
        self.label = label
        self.tableType = tableType
        self.dataFilePath = dataFilePath
        self.sheets = sheets ?? [
            Sheet.dataSheet(),
            Sheet.infoSheet(),
        ]
    }

    /// Create a new data table with default sheets.
    static func new(type: TableType, label: String) -> DataTable {
        DataTable(label: label, tableType: type)
    }

    /// Add a graph sheet for the given chart type.
    func addGraph(chartType: ChartType) -> Sheet {
        let sheet = Sheet.graphSheet(chartType: chartType)
        sheets.append(sheet)
        return sheet
    }

    /// Add a results sheet.
    func addResults(label: String = "Results") -> Sheet {
        let sheet = Sheet.resultsSheet(label: label)
        sheets.append(sheet)
        return sheet
    }

    /// Remove a sheet by ID.
    func removeSheet(id: UUID) {
        sheets.removeAll { $0.id == id }
    }
}
