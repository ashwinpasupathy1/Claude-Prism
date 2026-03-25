// DataTableView.swift — Read-only spreadsheet view of imported data.
// Shows a file picker if no data is loaded.

import SwiftUI
import UniformTypeIdentifiers

struct DataTableView: View {

    @Environment(AppState.self) private var appState

    @State private var columns: [String] = []
    @State private var rows: [[AnyCellValue]] = []
    @State private var isLoadingData = false
    @State private var dataShape: [Int] = [0, 0]
    @State private var dataError: String?

    var body: some View {
        if let table = appState.activeDataTable, table.hasData {
            dataPreview(table: table)
        } else {
            filePickerPrompt
        }
    }

    // MARK: - File Picker

    private var filePickerPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("Import Data")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Choose an Excel or CSV file to load into this table.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button("Open File...") {
                openFilePicker()
            }
            .buttonStyle(.borderedProminent)

            // Sample data button
            Button("Try Sample Data") {
                loadSampleData()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }

    // MARK: - Data Preview

    private func dataPreview(table: DataTable) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "tablecells")
                Text(table.dataFilePath?.components(separatedBy: "/").last ?? "Data")
                    .font(.headline)
                if !dataShape.isEmpty && dataShape[0] > 0 {
                    Text("\(dataShape[0]) rows × \(dataShape[1]) cols")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Change File...") {
                    openFilePicker()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content area
            if isLoadingData {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Spacer()
                }
                Spacer()
            } else if let error = dataError {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                Spacer()
            } else if columns.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No data to display.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                spreadsheetGrid
            }
        }
        .task(id: table.dataFilePath) {
            await fetchDataPreview(path: table.dataFilePath)
        }
    }

    // MARK: - Spreadsheet Grid

    private var spreadsheetGrid: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                        HStack(spacing: 0) {
                            // Row number
                            Text("\(rowIdx + 1)")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 44, alignment: .trailing)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))

                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell.displayString)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                            }
                        }
                        .background(rowIdx % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))

                        Divider()
                    }
                } header: {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text("#")
                                .fontWeight(.semibold)
                                .frame(width: 44, alignment: .trailing)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)

                            ForEach(Array(columns.enumerated()), id: \.offset) { _, name in
                                Text(name)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                            }
                        }
                        .background(.bar)

                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Data Fetching

    private func fetchDataPreview(path: String?) async {
        guard let path, !path.isEmpty else {
            columns = []
            rows = []
            dataShape = [0, 0]
            return
        }

        isLoadingData = true
        dataError = nil

        do {
            let response = try await APIClient.shared.dataPreview(excelPath: path)
            if response.ok {
                columns = response.columns ?? []
                rows = response.rows ?? []
                dataShape = response.shape ?? [0, 0]
                dataError = nil
            } else {
                dataError = response.error ?? "Unknown error"
                columns = []
                rows = []
            }
        } catch {
            dataError = error.localizedDescription
            columns = []
            rows = []
        }

        isLoadingData = false
    }

    // MARK: - Actions

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "xlsx")!,
            UTType(filenameExtension: "xls")!,
            UTType(filenameExtension: "csv")!,
        ]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await appState.uploadFile(url: url)
            }
        }
    }

    private func loadSampleData() {
        if let sampleURL = Bundle.main.url(forResource: "SampleData/drug_treatment", withExtension: "xlsx") {
            Task {
                await appState.uploadFile(url: sampleURL)
            }
        }
    }
}
