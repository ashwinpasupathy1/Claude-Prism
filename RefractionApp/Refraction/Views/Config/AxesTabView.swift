// AxesTabView.swift — Axis configuration: Y scale, limits, tick interval,
// reference line, axis style, tick direction, font size.

import SwiftUI

struct AxesTabView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var config = appState.chartConfig

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - Y Scale
                sectionHeader("Y Axis")

                LabeledContent("Scale") {
                    Picker("", selection: $config.yScale) {
                        Text("Linear").tag("linear")
                        Text("Log").tag("log")
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }

                HStack(spacing: 12) {
                    LabeledContent("Y Min") {
                        TextField("auto", text: $config.yMin)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }
                    LabeledContent("Y Max") {
                        TextField("auto", text: $config.yMax)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }
                }

                LabeledContent("Y Tick Interval") {
                    TextField("auto", value: $config.yTickInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }

                LabeledContent("X Tick Interval") {
                    TextField("auto", value: $config.xTickInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }

                Divider()

                // MARK: - Reference line
                sectionHeader("Reference Line")

                LabeledContent("Value") {
                    TextField("none", text: $config.refLineValue)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                LabeledContent("Label") {
                    TextField("label", text: $config.refLineLabel)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                Divider()

                // MARK: - Axis style
                sectionHeader("Appearance")

                LabeledContent("Axis Style") {
                    Picker("", selection: $config.axisStyle) {
                        ForEach(ChartConfig.AxisStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }

                LabeledContent("Tick Direction") {
                    Picker("", selection: $config.tickDirection) {
                        ForEach(ChartConfig.TickDirection.allCases) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                LabeledContent("Font Size") {
                    Slider(value: $config.fontSize, in: 8...24, step: 1) {
                        Text("\(Int(config.fontSize)) pt")
                    }
                    .frame(width: 140)
                }
                Text("\(Int(config.fontSize)) pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
