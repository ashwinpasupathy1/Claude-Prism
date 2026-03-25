// GraphSheetView.swift — Wraps ChartCanvasView with a minimal toolbar for graph sheets.
// Auto-generates the chart when the sheet appears or data changes.
// Double-click the chart to open the Format Graph dialog.

import SwiftUI

struct GraphSheetView: View {

    @Environment(AppState.self) private var appState
    let sheet: Sheet

    @State private var showFormatDialog = false
    @State private var showFormatAxesDialog = false

    var body: some View {
        VStack(spacing: 0) {
            // Minimal toolbar (chart type label + format button)
            graphToolbar
            Divider()

            // Chart canvas
            if sheet.isLoading {
                ProgressView("Generating chart...")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let spec = sheet.chartSpec {
                ChartCanvasView(spec: spec)
                    .onTapGesture(count: 2) {
                        showFormatDialog = true
                    }
                    .contextMenu {
                        Button("Format Graph...") {
                            showFormatDialog = true
                        }
                        Button("Format Axes...") {
                            showFormatAxesDialog = true
                        }
                    }
            } else if appState.activeDataTable?.hasData == true {
                ProgressView("Generating chart...")
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Import data into the data table first")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Developer mode: raw JSON panel
            if appState.developerMode, !sheet.rawJSON.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Engine Response", systemImage: "curlybraces")
                            .font(.headline)
                        Spacer()
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sheet.rawJSON, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.bar)

                    ScrollView {
                        Text(sheet.rawJSON)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 250)
            }
        }
        // Auto-generate when sheet appears or data path changes
        .task(id: appState.activeDataTable?.dataFilePath) {
            if appState.activeDataTable?.hasData == true, sheet.chartSpec == nil {
                await appState.generatePlot()
            }
        }
        .sheet(isPresented: $showFormatDialog) {
            FormatGraphDialog(settings: sheet.formatSettings)
        }
        .sheet(isPresented: $showFormatAxesDialog) {
            FormatAxesDialog(settings: sheet.formatAxesSettings)
        }
    }

    // MARK: - Toolbar

    private var graphToolbar: some View {
        HStack {
            if let chartType = sheet.chartType {
                Label(chartType.label, systemImage: chartType.sfSymbol)
                    .font(.headline)
            }
            Spacer()
            Button {
                showFormatDialog = true
            } label: {
                Label("Format", systemImage: "paintbrush")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button {
                showFormatAxesDialog = true
            } label: {
                Label("Axes", systemImage: "axis.horizontal.and.vertical")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
