// ResultsSheetView.swift — Prism-style statistical results display.
// Parses the raw JSON from the analysis engine and shows structured tables.

import SwiftUI

struct ResultsSheetView: View {

    @Environment(AppState.self) private var appState
    let sheet: Sheet

    /// Parsed results from the sheet's rawJSON.
    @State private var parsed: ParsedResults?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Label(sheet.label, systemImage: "list.clipboard")
                    .font(.headline)
                Spacer()
                if !sheet.rawJSON.isEmpty {
                    Button("Copy JSON") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(sheet.rawJSON, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            if let parsed {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Summary banner
                        if let summary = parsed.summary {
                            summaryBanner(summary, label: parsed.analysisLabel)
                        }

                        // Recommendation
                        if let rec = parsed.recommendation {
                            recommendationCard(rec)
                        }

                        // Descriptive statistics table
                        if !parsed.descriptive.isEmpty {
                            resultTable(
                                title: "Descriptive Statistics",
                                columns: ["Group", "n", "Mean", "SD", "SEM", "Median", "95% CI"],
                                rows: parsed.descriptive.map { d in
                                    [d.group, fmt(d.n), fmt(d.mean), fmt(d.sd), fmt(d.sem), fmt(d.median), fmt(d.ci95)]
                                }
                            )
                        }

                        // Normality tests table
                        if !parsed.normality.isEmpty {
                            resultTable(
                                title: "Normality Tests (Shapiro-Wilk)",
                                columns: ["Group", "W statistic", "p-value", "Normal?"],
                                rows: parsed.normality.map { n in
                                    [n.group, fmt(n.stat), fmt(n.p), n.normal ? "Yes" : "No"]
                                }
                            )
                        }

                        // Pairwise comparisons table
                        if !parsed.comparisons.isEmpty {
                            resultTable(
                                title: "Pairwise Comparisons",
                                columns: ["Group A", "Group B", "p-value", "Significance", "Effect Size", "Type"],
                                rows: parsed.comparisons.map { c in
                                    [c.groupA, c.groupB, fmt(c.pValue), c.stars, fmt(c.effectSize), c.effectType]
                                }
                            )
                        }
                    }
                    .padding()
                }

                // Developer mode: raw JSON
                if appState.developerMode, !sheet.rawJSON.isEmpty {
                    Divider()
                    ScrollView {
                        Text(sheet.rawJSON)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                }
            } else if sheet.rawJSON.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text("No results yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Run an analysis from the navigator to see results here.")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Parsing results...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: sheet.rawJSON) {
            parsed = ParsedResults.parse(json: sheet.rawJSON)
        }
    }

    // MARK: - Summary banner

    private func summaryBanner(_ summary: String, label: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Text(summary)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Recommendation card

    private func recommendationCard(_ rec: ParsedResults.Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                Text("Recommended: \(rec.testLabel)")
                    .fontWeight(.semibold)
                if let posthoc = rec.posthoc {
                    Text("+ \(posthoc)")
                        .foregroundStyle(.secondary)
                }
            }
            Text(rec.justification)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Result table

    private func resultTable(title: String, columns: [String], rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)

            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                            Text(col)
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: columnWidth(col), alignment: .leading)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 5)
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))

                    Divider()

                    // Data rows
                    ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                                Text(cell)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(
                                        width: columnWidth(colIdx < columns.count ? columns[colIdx] : ""),
                                        alignment: colIdx == 0 ? .leading : .trailing
                                    )
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                            }
                        }
                        .background(rowIdx % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func columnWidth(_ header: String) -> CGFloat {
        switch header {
        case "Group", "Group A", "Group B": return 100
        case "n": return 40
        case "Normal?", "Significance": return 80
        case "Type": return 80
        default: return 90
        }
    }

    // MARK: - Formatting

    private func fmt(_ val: Double?) -> String {
        guard let v = val else { return "—" }
        if v != v { return "—" }  // NaN
        if v == v.rounded() && abs(v) < 1e6 { return String(format: "%.0f", v) }
        if abs(v) < 0.001 { return String(format: "%.2e", v) }
        return String(format: "%.4f", v)
    }

    private func fmt(_ val: Int?) -> String {
        guard let v = val else { return "—" }
        return "\(v)"
    }
}

// MARK: - Parsed Results Model

private struct ParsedResults {
    let analysisLabel: String?
    let summary: String?
    let recommendation: Recommendation?
    let descriptive: [DescriptiveRow]
    let normality: [NormalityRow]
    let comparisons: [ComparisonRow]

    struct Recommendation {
        let test: String
        let testLabel: String
        let posthoc: String?
        let justification: String
    }

    struct DescriptiveRow {
        let group: String
        let n: Int?
        let mean: Double?
        let sd: Double?
        let sem: Double?
        let median: Double?
        let ci95: Double?
    }

    struct NormalityRow {
        let group: String
        let stat: Double?
        let p: Double?
        let normal: Bool
    }

    struct ComparisonRow {
        let groupA: String
        let groupB: String
        let pValue: Double?
        let stars: String
        let effectSize: Double?
        let effectType: String
    }

    static func parse(json: String) -> ParsedResults? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let analysisLabel = obj["analysis_label"] as? String
        let summary = obj["summary"] as? String

        // Recommendation
        var recommendation: Recommendation?
        if let rec = obj["recommendation"] as? [String: Any] {
            recommendation = Recommendation(
                test: rec["test"] as? String ?? "",
                testLabel: rec["test_label"] as? String ?? "",
                posthoc: rec["posthoc"] as? String,
                justification: rec["justification"] as? String ?? ""
            )
        }

        // Descriptive
        var descriptive: [DescriptiveRow] = []
        if let descs = obj["descriptive"] as? [[String: Any]] {
            for d in descs {
                descriptive.append(DescriptiveRow(
                    group: d["group"] as? String ?? "—",
                    n: d["n"] as? Int,
                    mean: d["mean"] as? Double,
                    sd: d["sd"] as? Double,
                    sem: d["sem"] as? Double,
                    median: d["median"] as? Double,
                    ci95: d["ci95"] as? Double
                ))
            }
        }

        // Normality
        var normality: [NormalityRow] = []
        if let norms = obj["normality"] as? [String: [String: Any]] {
            for (group, vals) in norms.sorted(by: { $0.key < $1.key }) {
                normality.append(NormalityRow(
                    group: group,
                    stat: vals["stat"] as? Double,
                    p: vals["p"] as? Double,
                    normal: vals["normal"] as? Bool ?? false
                ))
            }
        }

        // Comparisons
        var comparisons: [ComparisonRow] = []
        if let comps = obj["comparisons"] as? [[String: Any]] {
            for c in comps {
                comparisons.append(ComparisonRow(
                    groupA: c["group_a"] as? String ?? "—",
                    groupB: c["group_b"] as? String ?? "—",
                    pValue: c["p_value"] as? Double,
                    stars: c["stars"] as? String ?? "",
                    effectSize: c["effect_size"] as? Double,
                    effectType: c["effect_type"] as? String ?? ""
                ))
            }
        }

        return ParsedResults(
            analysisLabel: analysisLabel,
            summary: summary,
            recommendation: recommendation,
            descriptive: descriptive,
            normality: normality,
            comparisons: comparisons
        )
    }
}
