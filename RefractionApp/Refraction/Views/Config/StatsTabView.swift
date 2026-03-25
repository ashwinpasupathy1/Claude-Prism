// StatsTabView.swift — Statistical test configuration: test type, posthoc,
// correction, comparison mode, p-threshold, display toggles.

import SwiftUI

struct StatsTabView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        if let sheet = appState.activeSheet, sheet.kind == .graph,
           let config = sheet.chartConfig {
            @Bindable var config = config
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Test selection
                    sectionHeader("Statistical Test")

                    LabeledContent("Test") {
                        Picker("", selection: $config.statsTest) {
                            Text("Auto").tag("auto")
                            Text("Parametric").tag("parametric")
                            Text("Non-parametric").tag("nonparametric")
                            Text("Paired").tag("paired")
                            Text("None").tag("none")
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }

                    LabeledContent("Posthoc") {
                        Picker("", selection: $config.posthoc) {
                            Text("Tukey HSD").tag("tukey")
                            Text("Dunn").tag("dunn")
                            Text("Games-Howell").tag("games_howell")
                            Text("Dunnett").tag("dunnett")
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }

                    LabeledContent("Correction") {
                        Picker("", selection: $config.mcCorrection) {
                            Text("Holm-Bonferroni").tag("holm")
                            Text("Bonferroni").tag("bonferroni")
                            Text("Benjamini-Hochberg").tag("fdr_bh")
                            Text("None").tag("none")
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }

                    Divider()

                    // MARK: - Comparison mode
                    sectionHeader("Comparisons")

                    LabeledContent("Control Group") {
                        TextField("none", text: $config.control)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }

                    LabeledContent("p-threshold") {
                        TextField("0.05", value: $config.pThreshold, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }

                    LabeledContent("Bracket Style") {
                        Picker("", selection: $config.bracketStyle) {
                            Text("Bracket").tag("bracket")
                            Text("Line").tag("line")
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }

                    Divider()

                    // MARK: - Display toggles
                    sectionHeader("Display")

                    Toggle("Show n= counts", isOn: $config.showNs)
                    Toggle("Show p-values", isOn: $config.showPValues)
                    Toggle("Show effect sizes", isOn: $config.showEffectSize)
                    Toggle("Show test name", isOn: $config.showTestName)
                    Toggle("Show normality warning", isOn: $config.showNormalityWarning)

                    Spacer()
                }
                .padding()
            }
        } else {
            Text("Select a graph sheet")
                .foregroundStyle(.secondary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}
