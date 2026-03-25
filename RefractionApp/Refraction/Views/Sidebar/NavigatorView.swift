// NavigatorView.swift — Prism-style sidebar navigator.
// Sheets organized under subheaders: Data Tables, Info, Results, Graphs.

import SwiftUI

struct NavigatorView: View {

    @Environment(AppState.self) private var appState

    @State private var tableToDelete: DataTable?
    @State private var editingID: UUID?
    @State private var showAnalyzeDialog = false
    @State private var analyzeTableID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            newTableButton
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            if appState.dataTables.isEmpty {
                emptyState
            } else {
                tableList
            }
        }
        .listStyle(.sidebar)
        .alert(
            "Delete Data Table?",
            isPresented: Binding(
                get: { tableToDelete != nil },
                set: { if !$0 { tableToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let table = tableToDelete {
                    appState.removeDataTable(id: table.id)
                }
                tableToDelete = nil
            }
            Button("Cancel", role: .cancel) { tableToDelete = nil }
        } message: {
            if let table = tableToDelete {
                Text("Are you sure you want to delete \"\(table.label)\"? This will remove the table and all its sheets.")
            }
        }
        .sheet(isPresented: $showAnalyzeDialog) {
            AnalyzeDataDialog()
                .environment(appState)
        }
    }

    // MARK: - New Table Button

    private var newTableButton: some View {
        Menu {
            ForEach(TableType.allCases) { type in
                Button {
                    appState.addDataTable(type: type)
                } label: {
                    Label(type.label, systemImage: type.sfSymbol)
                }
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("New Data Table")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tablecells.badge.ellipsis")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("No data tables")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Create a new data table to get started.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Table List

    private var tableList: some View {
        List(selection: Binding(
            get: { appState.activeSheetID },
            set: { id in
                if let id { appState.selectSheet(id) }
            }
        )) {
            ForEach(appState.dataTables) { table in
                dataTableSection(table)
            }
        }
    }

    // MARK: - Data Table Section (Prism-style subheaders)

    @ViewBuilder
    private func dataTableSection(_ table: DataTable) -> some View {
        let dataSheets = table.sheets.filter { $0.kind == .dataTable }
        let infoSheets = table.sheets.filter { $0.kind == .info }
        let resultSheets = table.sheets.filter { $0.kind == .results }
        let graphSheets = table.sheets.filter { $0.kind == .graph }

        DisclosureGroup {
            // Data Tables subheader
            if !dataSheets.isEmpty {
                Section("Data Tables") {
                    ForEach(dataSheets) { sheet in
                        sheetRow(sheet, table: table)
                            .tag(sheet.id)
                    }
                }
            }

            // Info subheader
            Section("Info") {
                ForEach(infoSheets) { sheet in
                    sheetRow(sheet, table: table)
                        .tag(sheet.id)
                }
            }

            // Results subheader
            Section {
                ForEach(resultSheets) { sheet in
                    sheetRow(sheet, table: table)
                        .tag(sheet.id)
                }
                // New Analysis... button
                Button {
                    appState.activeDataTableID = table.id
                    analyzeTableID = table.id
                    showAnalyzeDialog = true
                } label: {
                    Label("New Analysis...", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } header: {
                Text("Results")
            }

            // Graphs subheader
            Section {
                ForEach(graphSheets) { sheet in
                    sheetRow(sheet, table: table)
                        .tag(sheet.id)
                }
                // New Graph... menu
                Menu {
                    ForEach(table.availableChartTypes) { chartType in
                        Button {
                            appState.activeDataTableID = table.id
                            appState.addGraph(chartType: chartType)
                        } label: {
                            Label(chartType.label, systemImage: chartType.sfSymbol)
                        }
                    }
                } label: {
                    Label("New Graph...", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
            } header: {
                Text("Graphs")
            }
        } label: {
            tableHeader(table)
        }
    }

    // MARK: - Table Header

    private func tableHeader(_ table: DataTable) -> some View {
        HStack {
            Image(systemName: table.tableType.sfSymbol)
                .foregroundStyle(.secondary)
            if editingID == table.id {
                TextField("Name", text: Bindable(table).label)
                    .textFieldStyle(.plain)
                    .fontWeight(.semibold)
                    .onSubmit { editingID = nil }
            } else {
                Text(table.label)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .onTapGesture(count: 2) { editingID = table.id }
            }
            Spacer()
            Button {
                tableToDelete = table
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button("Rename") { editingID = table.id }
            Button("Delete", role: .destructive) { tableToDelete = table }
        }
    }

    // MARK: - Sheet Row

    private func sheetRow(_ sheet: Sheet, table: DataTable) -> some View {
        Label {
            if editingID == sheet.id {
                TextField("Name", text: Bindable(sheet).label)
                    .textFieldStyle(.plain)
                    .onSubmit { editingID = nil }
            } else {
                Text(sheet.label)
                    .lineLimit(1)
                    .onTapGesture(count: 2) { editingID = sheet.id }
            }
        } icon: {
            Image(systemName: sheet.sfSymbol)
                .foregroundStyle(iconColor(for: sheet))
        }
        .contextMenu {
            Button("Rename") { editingID = sheet.id }
            if sheet.kind != .dataTable {
                Button("Delete", role: .destructive) {
                    table.removeSheet(id: sheet.id)
                }
            }
        }
    }

    private func iconColor(for sheet: Sheet) -> Color {
        switch sheet.kind {
        case .graph:    return .blue
        case .results:  return .orange
        case .info:     return .green
        case .dataTable: return .secondary
        }
    }
}
