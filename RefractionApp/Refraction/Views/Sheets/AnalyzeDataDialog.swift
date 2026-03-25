// AnalyzeDataDialog.swift — Prism-style "Analyze Data" dialog.
// Shows ALL statistical analyses organized by category. Analyses that aren't
// applicable to the current data table type or group count are shown grayed
// out with a reason. The recommended test is highlighted with a star icon.

import SwiftUI

// MARK: - Analysis Option Model

struct AnalysisOption: Identifiable, Hashable {
    let id: String       // key sent to backend (e.g. "anova")
    let label: String    // human-readable name
    let category: String // grouping header
    /// Required table type. nil = available in any table type.
    let requiredTableType: TableType?
    /// Minimum number of groups required (0 = no restriction).
    let minGroups: Int
    /// Maximum number of groups allowed (0 = no restriction).
    let maxGroups: Int
    /// Whether the analysis requires paired data.
    let requiresPaired: Bool

    init(
        id: String,
        label: String,
        category: String,
        requiredTableType: TableType? = nil,
        minGroups: Int = 0,
        maxGroups: Int = 0,
        requiresPaired: Bool = false
    ) {
        self.id = id
        self.label = label
        self.category = category
        self.requiredTableType = requiredTableType
        self.minGroups = minGroups
        self.maxGroups = maxGroups
        self.requiresPaired = requiresPaired
    }

    // Hashable conformance ignoring metadata fields
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: AnalysisOption, rhs: AnalysisOption) -> Bool { lhs.id == rhs.id }
}

// MARK: - Dialog View

struct AnalyzeDataDialog: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnalysis: String?
    @State private var recommendation: RecommendTestResponse?
    @State private var isLoadingRecommendation = false
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var showStatsWiki = false

    private var table: DataTable? { appState.activeDataTable }
    private var tableType: TableType? { table?.tableType }

    /// All analyses in display order.
    private var allAnalyses: [AnalysisOption] { Self.allAnalyses }

    /// Category headers in display order.
    private var categories: [String] {
        var seen: [String] = []
        for opt in allAnalyses {
            if !seen.contains(opt.category) {
                seen.append(opt.category)
            }
        }
        return seen
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            Text("Analyze Data")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            // Main content: two-panel layout
            HStack(spacing: 0) {
                // Left panel: analysis list
                analysisList
                    .frame(width: 280)

                Divider()

                // Right panel: recommendation + details
                detailPanel
                    .frame(minWidth: 300)
            }
            .frame(height: 400)

            Divider()

            // Bottom buttons
            HStack {
                Button {
                    showStatsWiki = true
                } label: {
                    Label("Statistics Guide", systemImage: "book.fill")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("OK") {
                    runAnalysis()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedAnalysis == nil || isRunning || !isSelectionEnabled)
            }
            .padding(16)
        }
        .frame(width: 640, height: 500)
        .task {
            await loadRecommendation()
        }
        .sheet(isPresented: $showStatsWiki) {
            StatsWikiDialog()
                .environment(appState)
        }
    }

    /// Whether the currently selected analysis is enabled (applicable).
    private var isSelectionEnabled: Bool {
        guard let sel = selectedAnalysis else { return false }
        guard let opt = allAnalyses.first(where: { $0.id == sel }) else { return false }
        return disableReason(for: opt) == nil
    }

    // MARK: - Left Panel

    private var analysisList: some View {
        List(selection: $selectedAnalysis) {
            ForEach(categories, id: \.self) { category in
                Section(category) {
                    ForEach(allAnalyses.filter { $0.category == category }) { option in
                        let reason = disableReason(for: option)
                        let isDisabled = reason != nil
                        let isRecommended = option.id == recommendation?.test

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(option.label)
                                    .foregroundStyle(isDisabled ? .secondary : .primary)
                                Spacer()
                                if isRecommended {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                        .help("Recommended")
                                }
                            }
                            if let reason {
                                Text(reason)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                        .tag(option.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .onChange(of: recommendation?.test) { _, newValue in
            // Auto-select recommended test if nothing selected yet
            if selectedAnalysis == nil, let rec = newValue {
                selectedAnalysis = rec
            }
        }
    }

    // MARK: - Right Panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingRecommendation {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Analyzing data...")
                    Spacer()
                }
                Spacer()
            } else if let rec = recommendation, rec.ok {
                // Recommendation card
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Recommended", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)

                        Text(rec.testLabel ?? rec.test ?? "Unknown")
                            .font(.title3)
                            .fontWeight(.semibold)

                        if let justification = rec.justification {
                            Text(justification)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let posthoc = rec.posthoc {
                            HStack(spacing: 4) {
                                Text("Post-hoc:")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(posthoc)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Selected analysis info
                if let sel = selectedAnalysis,
                   let option = allAnalyses.first(where: { $0.id == sel }) {
                    if sel != rec.test {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                let reason = disableReason(for: option)
                                if reason != nil {
                                    Label("Not applicable", systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("Selected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(option.label)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(reason != nil ? .secondary : .primary)
                                if let reason {
                                    Text(reason)
                                        .font(.callout)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Spacer()
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("Select an analysis from the list")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(16)
    }

    // MARK: - Disable Reason

    /// Returns nil if the analysis is applicable, or a short reason string if not.
    private func disableReason(for option: AnalysisOption) -> String? {
        let currentType = tableType
        let nGroups = recommendation?.checks?.nGroups ?? 0

        // Check table type requirement
        if let required = option.requiredTableType, required != currentType {
            return "Requires \(required.label) table"
        }

        // Check group count requirements
        if option.minGroups > 0 && nGroups > 0 && nGroups < option.minGroups {
            if option.minGroups == 2 && option.maxGroups == 2 {
                return "Requires exactly 2 groups"
            }
            return "Requires \(option.minGroups)+ groups"
        }
        if option.maxGroups > 0 && nGroups > option.maxGroups {
            return "Requires \(option.maxGroups == 2 ? "exactly 2" : "\(option.maxGroups) or fewer") groups"
        }

        // Check paired requirement
        if option.requiresPaired {
            if currentType != .comparison {
                return "Requires paired data"
            }
        }

        return nil
    }

    // MARK: - Actions

    private func loadRecommendation() async {
        guard let path = table?.dataFilePath, !path.isEmpty else { return }
        isLoadingRecommendation = true
        do {
            recommendation = try await APIClient.shared.recommendTest(excelPath: path)
        } catch {
            // Non-fatal: just don't show a recommendation
            recommendation = nil
        }
        isLoadingRecommendation = false
    }

    private func runAnalysis() {
        guard let analysisType = selectedAnalysis else { return }
        isRunning = true
        errorMessage = nil
        Task { @MainActor in
            await appState.runAnalysis(analysisType: analysisType)
            isRunning = false
            dismiss()
        }
    }

    // MARK: - Complete analysis catalogue (all types, all table types)

    static let allAnalyses: [AnalysisOption] = [
        // Column analyses
        AnalysisOption(id: "descriptive", label: "Descriptive statistics", category: "Column Analyses",
                       requiredTableType: .column),
        AnalysisOption(id: "column_stats", label: "Column statistics", category: "Column Analyses",
                       requiredTableType: .column),
        AnalysisOption(id: "normality", label: "Normality tests", category: "Column Analyses",
                       requiredTableType: .column),
        AnalysisOption(id: "unpaired_t", label: "Unpaired t-test", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 2, maxGroups: 2),
        AnalysisOption(id: "welch_t", label: "Welch's t-test", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 2, maxGroups: 2),
        AnalysisOption(id: "mann_whitney", label: "Mann-Whitney U test", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 2, maxGroups: 2),
        AnalysisOption(id: "anova", label: "One-way ANOVA", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 3),
        AnalysisOption(id: "welch_anova", label: "Welch's ANOVA", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 3),
        AnalysisOption(id: "kruskal_wallis", label: "Kruskal-Wallis test", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 3),
        AnalysisOption(id: "one_sample", label: "One-sample t-test", category: "Column Analyses",
                       requiredTableType: .column),
        AnalysisOption(id: "permutation", label: "Permutation test", category: "Column Analyses",
                       requiredTableType: .column, minGroups: 2),

        // Paired analyses
        AnalysisOption(id: "paired_t", label: "Paired t-test", category: "Paired Analyses",
                       requiredTableType: .comparison, minGroups: 2, maxGroups: 2, requiresPaired: true),
        AnalysisOption(id: "wilcoxon", label: "Wilcoxon signed-rank test", category: "Paired Analyses",
                       requiredTableType: .comparison, minGroups: 2, maxGroups: 2, requiresPaired: true),
        AnalysisOption(id: "repeated_measures", label: "Repeated measures ANOVA", category: "Paired Analyses",
                       requiredTableType: .comparison, minGroups: 3, requiresPaired: true),
        AnalysisOption(id: "friedman", label: "Friedman test", category: "Paired Analyses",
                       requiredTableType: .comparison, minGroups: 3, requiresPaired: true),

        // XY analyses
        AnalysisOption(id: "linear_regression", label: "Simple linear regression", category: "XY Analyses",
                       requiredTableType: .xy),
        AnalysisOption(id: "pearson", label: "Pearson correlation", category: "XY Analyses",
                       requiredTableType: .xy),
        AnalysisOption(id: "spearman", label: "Spearman correlation", category: "XY Analyses",
                       requiredTableType: .xy),
        AnalysisOption(id: "curve_fit", label: "Nonlinear regression (curve fit)", category: "XY Analyses",
                       requiredTableType: .xy),

        // Grouped analyses
        AnalysisOption(id: "two_way_anova", label: "Two-way ANOVA", category: "Grouped Analyses",
                       requiredTableType: .grouped),
        AnalysisOption(id: "multiple_t", label: "Multiple t-tests", category: "Grouped Analyses",
                       requiredTableType: .grouped),

        // Contingency analyses
        AnalysisOption(id: "chi_square", label: "Chi-square test", category: "Contingency Analyses",
                       requiredTableType: .contingency),
        AnalysisOption(id: "fisher_exact", label: "Fisher's exact test", category: "Contingency Analyses",
                       requiredTableType: .contingency),
        AnalysisOption(id: "chi_square_gof", label: "Chi-square goodness of fit", category: "Contingency Analyses",
                       requiredTableType: .contingency),

        // Survival analyses
        AnalysisOption(id: "log_rank", label: "Log-rank test", category: "Survival Analyses",
                       requiredTableType: .survival),
        AnalysisOption(id: "kaplan_meier", label: "Kaplan-Meier analysis", category: "Survival Analyses",
                       requiredTableType: .survival),
    ]

    // MARK: - Legacy helper (kept for compatibility)

    static func analyses(for tableType: TableType) -> [AnalysisOption] {
        allAnalyses.filter { opt in
            opt.requiredTableType == nil || opt.requiredTableType == tableType
        }
    }
}
