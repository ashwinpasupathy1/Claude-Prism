// StyleSettingsDialog.swift — Dialog for visual style configuration.
// Opened from the toolbar Style button. Wraps the same controls as StyleTabView.

import SwiftUI

struct StyleSettingsDialog: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Style Settings")
                .font(.headline)
                .padding(12)

            Divider()

            if let graph = appState.activeGraph {
                let chartType = graph.chartType
                @Bindable var config = graph.chartConfig
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // MARK: - Render Style
                        sectionHeader("Render Style")

                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: Binding(
                                get: { graph.renderStyle },
                                set: { newStyle in
                                    graph.applyRenderStyle(newStyle)
                                }
                            )) {
                                ForEach(RenderStyle.allCases) { style in
                                    Text(style.label).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(graph.renderStyle.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // MARK: - Error bars
                        if chartType.hasErrorBars {
                            sectionHeader("Error Bars")

                            LabeledContent("Type") {
                                Picker("", selection: $config.errorType) {
                                    ForEach(ChartConfig.ErrorType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 100)
                            }

                            LabeledContent("Cap Size") {
                                Slider(value: $config.capSize, in: 0...10, step: 1)
                                    .frame(width: 120)
                            }

                            Divider()
                        }

                        // MARK: - Data points
                        if chartType.hasPoints {
                            sectionHeader("Data Points")

                            Toggle("Show Points", isOn: $config.showPoints)

                            if config.showPoints {
                                LabeledContent("Size") {
                                    Slider(value: $config.pointSize, in: 2...16, step: 1)
                                        .frame(width: 120)
                                }

                                LabeledContent("Opacity") {
                                    Slider(value: $config.pointAlpha, in: 0.1...1.0, step: 0.05)
                                        .frame(width: 120)
                                }

                                LabeledContent("Jitter") {
                                    Slider(value: $config.jitter, in: 0...0.5, step: 0.05)
                                        .frame(width: 120)
                                }
                            }

                            Divider()
                        }

                        // MARK: - Grid
                        sectionHeader("Grid")

                        LabeledContent("Grid Style") {
                            Picker("", selection: $config.gridStyle) {
                                ForEach(ChartConfig.GridStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }

                        Divider()

                        // MARK: - Layout
                        sectionHeader("Layout")

                        LabeledContent("Bar Width") {
                            Slider(value: $config.barWidth, in: 0.2...1.0, step: 0.05)
                                .frame(width: 120)
                        }

                        LabeledContent("Opacity") {
                            Slider(value: $config.alpha, in: 0.1...1.0, step: 0.05)
                                .frame(width: 120)
                        }

                        LabeledContent("Spine Width") {
                            Slider(value: $config.spineWidth, in: 0.5...3.0, step: 0.1)
                                .frame(width: 120)
                        }
                    }
                    .padding()
                }
                .frame(minHeight: 400)
            } else {
                Text("Select a graph first")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Bottom buttons
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
        .frame(width: 480)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}
