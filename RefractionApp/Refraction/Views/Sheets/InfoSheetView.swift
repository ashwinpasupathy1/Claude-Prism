// InfoSheetView.swift — Notes and metadata editor for a data table.

import SwiftUI

struct InfoSheetView: View {

    @Environment(AppState.self) private var appState
    let sheet: Sheet

    private var parentTable: DataTable? {
        appState.dataTables.first { table in
            table.sheets.contains { $0.id == sheet.id }
        }
    }

    private var graphSheets: [Sheet] {
        parentTable?.sheets.filter { $0.kind == .graph } ?? []
    }

    var body: some View {
        Form {
            Section("Table") {
                if let table = parentTable {
                    TextField("Name", text: Binding(
                        get: { table.label },
                        set: { table.label = $0 }
                    ))
                    LabeledContent("Type", value: table.tableType.label)
                } else {
                    Text("Unknown table")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data") {
                if let path = parentTable?.dataFilePath, !path.isEmpty {
                    LabeledContent("File path", value: path)
                } else {
                    LabeledContent("File path", value: "No data loaded")
                }
                LabeledContent("Sheets", value: "\(parentTable?.sheets.count ?? 0)")
            }

            Section("Graphs") {
                if graphSheets.isEmpty {
                    Text("No graphs yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(graphSheets) { gs in
                        LabeledContent(
                            gs.label,
                            value: gs.chartType?.label ?? "—"
                        )
                    }
                }
            }

            Section("Dates") {
                LabeledContent("Created", value: "—")
            }

            Section("Notes") {
                TextEditor(text: Binding(
                    get: { sheet.notes },
                    set: { sheet.notes = $0 }
                ))
                .font(.body)
                .frame(minHeight: 120)
            }
        }
        .formStyle(.grouped)
    }
}
