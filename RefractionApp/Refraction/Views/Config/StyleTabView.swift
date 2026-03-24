// StyleTabView.swift — Visual style configuration: error bars, points,
// theme picker, grid style, legend options.

import SwiftUI

struct StyleTabView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var config = appState.chartConfig

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - Error bars
                if appState.selectedChartType.hasErrorBars {
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
                if appState.selectedChartType.hasPoints {
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

                Spacer()
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}
