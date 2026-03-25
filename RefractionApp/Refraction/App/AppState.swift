// AppState.swift — Central observable state for the Refraction app.
// Manages multiple data tables, each with their own sheets (graphs, results, info).

import AppKit
import Foundation
import RefractionRenderer
import UniformTypeIdentifiers

@Observable
final class AppState {

    // MARK: - Multi-table state

    /// All data tables in the project.
    var dataTables: [DataTable] = []

    /// Currently selected data table ID.
    var activeDataTableID: UUID?

    /// Currently selected sheet ID.
    var activeSheetID: UUID?

    /// Developer mode: show raw JSON from the engine for debugging.
    var developerMode: Bool = false

    /// Current project file path (nil = never saved).
    var projectFilePath: URL?

    /// Whether the project has unsaved changes.
    var hasUnsavedChanges: Bool = false

    /// Display name for the title bar.
    var projectDisplayName: String {
        if let path = projectFilePath {
            let name = path.deletingPathExtension().lastPathComponent
            return hasUnsavedChanges ? "\(name) — Edited" : name
        }
        return hasUnsavedChanges ? "Untitled.refract — Edited" : "Untitled.refract"
    }

    /// Whether any render request is in flight.
    var isLoading: Bool = false

    /// Most recent error message (nil = no error).
    var error: String?

    // MARK: - Computed properties

    /// The active data table.
    var activeDataTable: DataTable? {
        dataTables.first { $0.id == activeDataTableID }
    }

    /// The active sheet.
    var activeSheet: Sheet? {
        guard let table = activeDataTable else { return nil }
        return table.sheets.first { $0.id == activeSheetID }
    }

    /// Whether any data table exists.
    var hasDataTables: Bool {
        !dataTables.isEmpty
    }

    // MARK: - Data Table Management

    /// Add a new data table and select it.
    @discardableResult
    func addDataTable(type: TableType, label: String? = nil) -> DataTable {
        let name = label ?? "\(type.label) \(dataTables.count + 1)"
        let table = DataTable.new(type: type, label: name)
        dataTables.append(table)
        activeDataTableID = table.id
        // Select the data sheet by default
        if let first = table.sheets.first {
            activeSheetID = first.id
        }
        markDirty()
        return table
    }

    /// Remove a data table.
    func removeDataTable(id: UUID) {
        dataTables.removeAll { $0.id == id }
        markDirty()
        if activeDataTableID == id {
            activeDataTableID = dataTables.first?.id
            activeSheetID = dataTables.first?.sheets.first?.id
        }
    }

    /// Add a graph sheet to the active data table and auto-generate the chart.
    @discardableResult
    func addGraph(chartType: ChartType) -> Sheet? {
        guard let table = activeDataTable else { return nil }
        let sheet = table.addGraph(chartType: chartType)
        // Copy the data file path into the graph's config
        if let path = table.dataFilePath {
            sheet.chartConfig?.excelPath = path
        }
        activeSheetID = sheet.id
        // Auto-generate the chart immediately
        Task { @MainActor in
            await generatePlot()
        }
        return sheet
    }

    /// Add a results sheet to the active data table.
    @discardableResult
    func addResults(label: String = "Results") -> Sheet? {
        guard let table = activeDataTable else { return nil }
        let sheet = table.addResults(label: label)
        activeSheetID = sheet.id
        return sheet
    }

    /// Select a sheet (and its parent data table).
    func selectSheet(_ sheetID: UUID) {
        for table in dataTables {
            if table.sheets.contains(where: { $0.id == sheetID }) {
                activeDataTableID = table.id
                activeSheetID = sheetID
                return
            }
        }
    }

    // MARK: - File Loading

    /// Upload a file and associate it with the active data table.
    @MainActor
    func uploadFile(url: URL) async {
        guard let table = activeDataTable else { return }
        do {
            let serverPath = try await APIClient.shared.upload(fileURL: url)
            table.dataFilePath = serverPath
            // Update all graph sheets in this table with the new path
            for sheet in table.sheets where sheet.kind == .graph {
                sheet.chartConfig?.excelPath = serverPath
            }
        } catch let apiError as APIError {
            self.error = "File upload failed: \(apiError.localizedDescription)"
        } catch {
            self.error = "File upload failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Chart Generation

    /// Generate the chart for the active graph sheet.
    @MainActor
    func generatePlot() async {
        guard let table = activeDataTable,
              let sheet = activeSheet,
              sheet.kind == .graph,
              let chartType = sheet.chartType,
              let config = sheet.chartConfig else {
            error = "Select a graph sheet first."
            return
        }

        guard let dataPath = table.dataFilePath, !dataPath.isEmpty else {
            error = "No data file loaded. Import data into the data table first."
            return
        }

        // Ensure the config has the correct data path
        config.excelPath = dataPath

        sheet.isLoading = true
        isLoading = true
        error = nil

        // Retry once after a short delay if the server isn't ready yet
        for attempt in 0..<2 {
            do {
                let (spec, rawJSON) = try await APIClient.shared.analyzeWithRawJSON(
                    chartType: chartType,
                    config: config
                )
                sheet.chartSpec = spec
                sheet.rawJSON = rawJSON
                self.error = nil
                break
            } catch {
                if attempt == 0 {
                    // Server may still be starting — wait and retry
                    try? await Task.sleep(for: .seconds(2))
                    continue
                }
                self.error = "Analysis failed: \(error.localizedDescription)"
                sheet.chartSpec = nil
            }
        }

        sheet.isLoading = false
        isLoading = false
    }

    // MARK: - Sample Data

    /// Create a data table with sample data and a default graph, all in one shot.
    @MainActor
    func loadSampleTable(type: TableType) async {
        let sampleURL: URL? =
            Bundle.main.url(forResource: type.sampleDataFilename, withExtension: "xlsx", subdirectory: "SampleData")
            ?? Bundle.main.url(forResource: type.sampleDataFilename, withExtension: "xlsx")

        guard let url = sampleURL, FileManager.default.fileExists(atPath: url.path) else {
            error = "Sample data for \(type.label) not found in app bundle."
            return
        }

        let chartType = type.defaultChartType
        let table = addDataTable(type: type, label: "\(chartType.label) Sample")

        // Upload the file
        let serverPath: String
        do {
            serverPath = try await APIClient.shared.upload(fileURL: url)
        } catch {
            self.error = "Failed to load sample data: \(error.localizedDescription)"
            return
        }

        // Set the data path on the table and all existing sheets
        table.dataFilePath = serverPath
        for sheet in table.sheets where sheet.kind == .graph {
            sheet.chartConfig?.excelPath = serverPath
        }

        // Add graph sheet with correct path, then generate directly (no Task race)
        guard let table2 = activeDataTable else { return }
        let sheet = table2.addGraph(chartType: chartType)
        sheet.chartConfig?.excelPath = serverPath
        activeSheetID = sheet.id

        // Generate synchronously in this async context
        await generatePlot()
    }

    // MARK: - Project Persistence

    /// Build a ProjectState snapshot from the current navigator tree.
    func saveProjectState() -> ProjectState {
        ProjectState(
            dataTables: dataTables.map { table in
                ProjectState.TableState(
                    id: table.id.uuidString,
                    label: table.label,
                    tableType: table.tableType.rawValue,
                    dataFilePath: table.dataFilePath,
                    sheets: table.sheets.map { sheet in
                        ProjectState.SheetState(
                            id: sheet.id.uuidString,
                            label: sheet.label,
                            kind: sheet.kind.rawValue,
                            chartType: sheet.chartType?.rawValue,
                            notes: sheet.notes.isEmpty ? nil : sheet.notes
                        )
                    }
                )
            },
            activeDataTableID: activeDataTableID?.uuidString,
            activeSheetID: activeSheetID?.uuidString
        )
    }

    /// Return the project state as pretty-printed JSON.
    func projectStateJSON() -> String {
        let state = saveProjectState()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(state) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Persist the current project state to ~/.refraction/project.json.
    func saveProject() {
        saveProjectState().writeToDisk()
    }

    /// Load project state from disk if the file exists, restoring the navigator tree.
    /// Only restores tables whose data files still exist on disk.
    func loadProjectIfExists() {
        guard let state = ProjectState.readFromDisk() else { return }
        var restoredTables: [DataTable] = []
        for ts in state.dataTables {
            guard let tableID = UUID(uuidString: ts.id),
                  let tableType = TableType(rawValue: ts.tableType) else { continue }

            // Skip tables whose data files no longer exist (temp files from previous session)
            if let path = ts.dataFilePath, !path.isEmpty,
               !FileManager.default.fileExists(atPath: path) {
                continue
            }

            var sheets: [Sheet] = []
            for ss in ts.sheets {
                guard let sheetID = UUID(uuidString: ss.id),
                      let kind = SheetKind(rawValue: ss.kind) else { continue }
                let chartType: ChartType? = ss.chartType.flatMap { ChartType(rawValue: $0) }
                let sheet = Sheet(id: sheetID, kind: kind, label: ss.label, chartType: chartType)
                if let notes = ss.notes {
                    sheet.notes = notes
                }
                sheets.append(sheet)
            }
            let table = DataTable(
                id: tableID,
                label: ts.label,
                tableType: tableType,
                dataFilePath: ts.dataFilePath,
                sheets: sheets
            )
            restoredTables.append(table)
        }
        guard !restoredTables.isEmpty else { return }
        dataTables = restoredTables
        activeDataTableID = state.activeDataTableID.flatMap { UUID(uuidString: $0) }
        activeSheetID = state.activeSheetID.flatMap { UUID(uuidString: $0) }
    }

    // MARK: - Statistical Analysis

    /// Run a standalone statistical analysis and create a Results sheet.
    @MainActor
    func runAnalysis(analysisType: String) async {
        guard let table = activeDataTable else {
            error = "No active data table."
            return
        }
        guard let dataPath = table.dataFilePath, !dataPath.isEmpty else {
            error = "No data file loaded. Import data first."
            return
        }

        isLoading = true
        error = nil

        do {
            let response = try await APIClient.shared.analyzeStats(
                excelPath: dataPath,
                analysisType: analysisType
            )

            guard response.ok else {
                error = response.error ?? "Analysis failed."
                isLoading = false
                return
            }

            // Create a Results sheet with the analysis output
            let label = response.analysisLabel ?? analysisType
            let sheet = table.addResults(label: label)

            // Store the raw JSON on the sheet for display
            sheet.rawJSON = response.rawJSON

            // Build summary notes for the results sheet
            var notes = "# \(label)\n\n"
            if let summary = response.summary {
                notes += "## Summary\n\(summary)\n\n"
            }
            if let descriptive = response.descriptive {
                notes += "## Descriptive Statistics\n"
                for group in descriptive {
                    let name = group["group"]?.displayString ?? "—"
                    let n = group["n"]?.displayString ?? "—"
                    let mean = group["mean"]?.displayString ?? "—"
                    let sd = group["sd"]?.displayString ?? "—"
                    let sem = group["sem"]?.displayString ?? "—"
                    notes += "  \(name): n=\(n), mean=\(mean), SD=\(sd), SEM=\(sem)\n"
                }
                notes += "\n"
            }
            if let comparisons = response.comparisons, !comparisons.isEmpty {
                notes += "## Comparisons\n"
                for comp in comparisons {
                    let ga = comp["group_a"]?.displayString ?? "—"
                    let gb = comp["group_b"]?.displayString ?? "—"
                    let p = comp["p_value"]?.displayString ?? "—"
                    let stars = comp["stars"]?.displayString ?? ""
                    notes += "  \(ga) vs \(gb): p = \(p) \(stars)\n"
                }
                notes += "\n"
            }
            if let rec = response.recommendation {
                notes += "## Recommendation\n"
                notes += "  \(rec.testLabel): \(rec.justification)\n"
            }
            sheet.notes = notes

            activeSheetID = sheet.id
        } catch {
            self.error = "Analysis failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Save as .refract File

    /// Save the project. If never saved before, prompt for a filename.
    /// If already saved, overwrite the same path silently.
    @MainActor
    func saveProjectFile() async {
        if let existingPath = projectFilePath {
            // Already saved — overwrite
            await saveToPath(existingPath)
        } else {
            // Never saved — prompt for filename
            await saveProjectFileAs()
        }
    }

    /// Always prompt for a new filename (Save As).
    @MainActor
    func saveProjectFileAs() async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "refract") ?? .data
        ]
        panel.nameFieldStringValue = projectFilePath?.lastPathComponent ?? "Untitled.refract"
        panel.title = "Save Project"
        panel.prompt = "Save"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        await saveToPath(url)
    }

    /// Write the project to a specific path.
    @MainActor
    private func saveToPath(_ url: URL) async {
        let projectDict = buildFullProjectDict()

        do {
            let _ = try await APIClient.shared.saveProject(
                outputPath: url.path,
                projectState: projectDict
            )
            projectFilePath = url
            hasUnsavedChanges = false
        } catch {
            self.error = "Save failed: \(error.localizedDescription)"
        }
    }

    /// Mark the project as having unsaved changes.
    func markDirty() {
        hasUnsavedChanges = true
    }

    /// Build a full project dict that includes chart configs and format settings
    /// for each sheet, suitable for sending to the /project/save-refract endpoint.
    private func buildFullProjectDict() -> [String: Any] {
        let tables: [[String: Any]] = dataTables.map { table in
            let sheets: [[String: Any]] = table.sheets.map { sheet in
                var sheetDict: [String: Any] = [
                    "id": sheet.id.uuidString,
                    "label": sheet.label,
                    "kind": sheet.kind.rawValue,
                ]
                if let ct = sheet.chartType {
                    sheetDict["chartType"] = ct.rawValue
                }
                if !sheet.notes.isEmpty {
                    sheetDict["notes"] = sheet.notes
                }
                // Include chart config for graph sheets
                if sheet.kind == .graph, let config = sheet.chartConfig {
                    sheetDict["chartConfig"] = config.toDict()
                }
                // Include format settings (Codable -> dict)
                if sheet.kind == .graph {
                    if let fgData = try? JSONEncoder().encode(sheet.formatSettings),
                       let fgDict = try? JSONSerialization.jsonObject(with: fgData) as? [String: Any] {
                        sheetDict["formatSettings"] = fgDict
                    }
                    if let faData = try? JSONEncoder().encode(sheet.formatAxesSettings),
                       let faDict = try? JSONSerialization.jsonObject(with: faData) as? [String: Any] {
                        sheetDict["formatAxesSettings"] = faDict
                    }
                }
                return sheetDict
            }

            var tableDict: [String: Any] = [
                "id": table.id.uuidString,
                "label": table.label,
                "tableType": table.tableType.rawValue,
                "sheets": sheets,
            ]
            if let path = table.dataFilePath {
                tableDict["dataFilePath"] = path
            }
            return tableDict
        }

        return [
            "dataTables": tables,
            "activeDataTableID": activeDataTableID?.uuidString ?? "",
            "activeSheetID": activeSheetID?.uuidString ?? "",
        ]
    }

    /// Clear error state.
    func dismissError() {
        error = nil
    }

    /// Retry the last action.
    @MainActor
    func retryLastAction() async {
        error = nil
        await generatePlot()
    }
}
