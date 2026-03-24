// ResultsView.swift — Displays statistical results beneath the chart:
// pairwise comparisons table, descriptive stats, normality results,
// and copy-to-clipboard functionality.

import SwiftUI
import RefractionRenderer

struct ResultsView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        if let spec = appState.currentSpec, let stats = spec.stats {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Pairwise comparisons
                    if !stats.comparisons.isEmpty {
                        sectionHeader("Pairwise Comparisons")

                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                            GridRow {
                                headerCell("Group 1")
                                headerCell("Group 2")
                                headerCell("p-value")
                                headerCell("Sig.")
                                headerCell("Label")
                            }

                            ForEach(Array(stats.comparisons.enumerated()), id: \.offset) { _, comp in
                                GridRow {
                                    Text(comp.group1)
                                        .font(.system(.body, design: .monospaced))
                                    Text(comp.group2)
                                        .font(.system(.body, design: .monospaced))
                                    Text(formatP(comp.pValue))
                                        .font(.system(.body, design: .monospaced))
                                    Image(systemName: comp.significant ? "checkmark.circle.fill" : "xmark.circle")
                                        .foregroundStyle(comp.significant ? .green : .secondary)
                                    Text(comp.label)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // MARK: - Descriptive stats
                    if !spec.groups.isEmpty {
                        Divider()
                        sectionHeader("Descriptive Statistics")

                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                            GridRow {
                                headerCell("Group")
                                headerCell("n")
                                headerCell("Mean")
                                headerCell("SEM")
                                headerCell("SD")
                            }

                            ForEach(spec.groups) { group in
                                GridRow {
                                    Text(group.name)
                                        .font(.system(.body, design: .monospaced))
                                    Text("\(group.values.n)")
                                        .font(.system(.body, design: .monospaced))
                                    Text(formatNum(group.values.mean))
                                        .font(.system(.body, design: .monospaced))
                                    Text(formatNum(group.values.sem))
                                        .font(.system(.body, design: .monospaced))
                                    Text(formatNum(group.values.sd))
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // MARK: - Normality
                    if let normality = stats.normality {
                        Divider()
                        sectionHeader("Normality")

                        HStack {
                            Text(normality.testName)
                                .font(.subheadline)
                            Text("p = \(formatP(normality.pValue))")
                                .font(.system(.subheadline, design: .monospaced))
                            Image(systemName: normality.isNormal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(normality.isNormal ? .green : .orange)
                            Text(normality.isNormal ? "Normal" : "Non-normal")
                                .foregroundStyle(normality.isNormal ? .green : .orange)
                        }

                        if let warning = normality.warning, !warning.isEmpty {
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    // MARK: - Copy button
                    Divider()

                    Button {
                        copyResultsToClipboard(spec: spec, stats: stats)
                    } label: {
                        Label("Copy Results", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()
                }
                .padding()
            }
        } else {
            ContentUnavailableView(
                "No Results",
                systemImage: "chart.bar.doc.horizontal",
                description: Text("Generate a plot with statistics enabled to see results here.")
            )
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func headerCell(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func formatP(_ p: Double) -> String {
        if p < 0.001 { return "<0.001" }
        return String(format: "%.4f", p)
    }

    private func formatNum(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "%.3f", v)
    }

    private func copyResultsToClipboard(spec: ChartSpec, stats: StatsResult) {
        var text = "Statistical Results\n"
        text += "Test: \(stats.testName)\n\n"

        if !stats.comparisons.isEmpty {
            text += "Pairwise Comparisons:\n"
            for c in stats.comparisons {
                text += "\(c.group1) vs \(c.group2): p=\(formatP(c.pValue)) \(c.label)\n"
            }
            text += "\n"
        }

        text += "Descriptive Statistics:\n"
        text += "Group\tn\tMean\tSEM\tSD\n"
        for g in spec.groups {
            text += "\(g.name)\t\(g.values.n)\t"
            text += "\(formatNum(g.values.mean))\t"
            text += "\(formatNum(g.values.sem))\t"
            text += "\(formatNum(g.values.sd))\n"
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
