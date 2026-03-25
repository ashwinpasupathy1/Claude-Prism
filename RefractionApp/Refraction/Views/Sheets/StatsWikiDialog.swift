// StatsWikiDialog.swift — Educational reference for statistical tests.
// Shows diagnostic results, decision tree, and a complete test catalog
// with applicability indicators based on the current data.

import SwiftUI

// MARK: - Test Catalog Model

struct StatTestEntry: Identifiable {
    let id: String
    let name: String
    let description: String
    let whenToUse: String
    let assumptions: [String]
    let category: StatTestCategory
}

enum StatTestCategory: String, CaseIterable {
    case parametric = "Parametric (assumes normality)"
    case nonparametric = "Nonparametric (no normality assumption)"
    case categorical = "Categorical / Count data"
    case correlation = "Correlation & Regression"
    case survival = "Survival"
    case other = "Other"
}

// MARK: - Dialog View

struct StatsWikiDialog: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var recommendation: RecommendTestResponse?
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedTestDetail: StatsTestDetail?

    private var table: DataTable? { appState.activeDataTable }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Statistics Guide")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            if isLoading {
                Spacer()
                ProgressView("Analyzing data...")
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Your Data card
                        if let checks = recommendation?.checks {
                            yourDataCard(checks)
                        }

                        // Decision tree
                        if let rec = recommendation, rec.ok {
                            decisionTreeCard(rec)
                        }

                        // Search
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search tests...", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(8)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Complete test reference
                        testCatalog
                    }
                    .padding(20)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 700, height: 680)
        .sheet(item: $selectedTestDetail) { detail in
            StatsTestDetailDialog(detail: detail)
        }
        .task {
            await loadRecommendation()
        }
    }

    // MARK: - Your Data Card

    private func yourDataCard(_ checks: DiagnosticChecks) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label("Your Data", systemImage: "tablecells")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    GridRow {
                        Text("Groups:")
                            .foregroundStyle(.secondary)
                        Text("\(checks.nGroups)")
                            .fontWeight(.medium)
                    }
                    GridRow {
                        Text("Paired:")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: checks.paired ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(checks.paired ? .green : .secondary)
                            Text(checks.paired ? "Yes" : "No")
                        }
                    }
                    GridRow {
                        Text("Normality:")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: checks.allNormal ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(checks.allNormal ? .green : .orange)
                            Text(checks.allNormal ? "All groups normal" : "Not all groups normal")
                        }
                    }
                    GridRow {
                        Text("Equal variance:")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: checks.equalVariance ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(checks.equalVariance ? .green : .orange)
                            if let lp = checks.leveneP {
                                Text("\(checks.equalVariance ? "Yes" : "No") (Levene's p = \(lp, specifier: "%.4f"))")
                            } else {
                                Text(checks.equalVariance ? "Yes" : "No")
                            }
                        }
                    }
                }

                // Per-group normality breakdown
                if !checks.normality.isEmpty {
                    Divider()
                    Text("Normality per group (Shapiro-Wilk)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(checks.normality.sorted(by: { $0.key < $1.key }), id: \.key) { name, result in
                        HStack(spacing: 6) {
                            Image(systemName: result.normal ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(result.normal ? .green : .orange)
                                .font(.caption)
                            Text(name)
                                .font(.caption)
                                .fontWeight(.medium)
                            if let p = result.p {
                                Text("p = \(p, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("n < 3")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Decision Tree Card

    private func decisionTreeCard(_ rec: RecommendTestResponse) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label("Decision Path", systemImage: "arrow.triangle.branch")
                    .font(.headline)

                if let checks = rec.checks {
                    let steps = buildDecisionPath(checks, recommendedTest: rec.test)
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 8) {
                            Image(systemName: step.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(step.passed ? .green : .orange)
                                .font(.callout)
                            Text(step.label)
                                .font(.callout)
                                .fontWeight(step.isFinal ? .bold : .regular)
                            if index < steps.count - 1 {
                                Spacer()
                                Image(systemName: "arrow.down")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption2)
                            }
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text(rec.testLabel ?? rec.test ?? "Unknown")
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)

                if let justification = rec.justification {
                    Text(justification)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Test Catalog

    private var testCatalog: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Complete Test Reference")
                .font(.headline)

            ForEach(StatTestCategory.allCases, id: \.rawValue) { category in
                let tests = Self.allTests.filter { $0.category == category }
                let filtered = searchText.isEmpty ? tests : tests.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.description.localizedCaseInsensitiveContains(searchText)
                }
                if !filtered.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(filtered) { test in
                            testRow(test)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTestDetail = StatsTestCatalog.detail(for: test.id)
                                }
                        }
                    }
                }
            }
        }
    }

    private func testRow(_ test: StatTestEntry) -> some View {
        let applicability = checkApplicability(test)
        let isRecommended = test.id == recommendation?.test
        let isApplicable = applicability == nil

        return GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(test.name)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(isApplicable ? .primary : .secondary)
                    if isRecommended {
                        Label("Recommended", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    if !isApplicable {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    if StatsTestCatalog.detail(for: test.id) != nil {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }

                Text(test.description)
                    .font(.caption)
                    .foregroundStyle(isApplicable ? .primary : .tertiary)

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("When to use")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        Text(test.whenToUse)
                            .font(.caption2)
                            .foregroundStyle(isApplicable ? .secondary : .tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assumptions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        ForEach(test.assumptions, id: \.self) { assumption in
                            Text("- \(assumption)")
                                .font(.caption2)
                                .foregroundStyle(isApplicable ? .secondary : .tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let reason = applicability {
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(isApplicable ? 1.0 : 0.6)
    }

    // MARK: - Applicability Check

    /// Returns nil if applicable, or a reason string if not.
    private func checkApplicability(_ test: StatTestEntry) -> String? {
        guard let checks = recommendation?.checks else { return nil }

        let n = checks.nGroups
        let paired = checks.paired
        let normal = checks.allNormal

        switch test.id {
        case "unpaired_t":
            if n != 2 { return "Requires exactly 2 groups (you have \(n))" }
            if paired { return "Requires independent (unpaired) groups" }
            if !normal { return "Data not normally distributed" }
            if !checks.equalVariance { return "Unequal variances -- use Welch's t-test" }
        case "welch_t":
            if n != 2 { return "Requires exactly 2 groups (you have \(n))" }
            if paired { return "Requires independent (unpaired) groups" }
            if !normal { return "Data not normally distributed" }
        case "paired_t":
            if n != 2 { return "Requires exactly 2 groups (you have \(n))" }
            if !paired { return "Requires paired/matched data" }
            if !normal { return "Differences not normally distributed" }
        case "anova":
            if n < 3 { return "Requires 3+ groups (you have \(n))" }
            if paired { return "Requires independent groups" }
            if !normal { return "Data not normally distributed" }
            if !checks.equalVariance { return "Unequal variances -- use Welch's ANOVA" }
        case "welch_anova":
            if n < 3 { return "Requires 3+ groups (you have \(n))" }
            if paired { return "Requires independent groups" }
            if !normal { return "Data not normally distributed" }
        case "repeated_measures_anova":
            if n < 3 { return "Requires 3+ groups (you have \(n))" }
            if !paired { return "Requires paired/repeated measures data" }
        case "two_way_anova":
            if n < 2 { return "Requires structured factorial data" }
        case "mann_whitney":
            if n != 2 { return "Requires exactly 2 groups (you have \(n))" }
            if paired { return "Requires independent groups" }
        case "wilcoxon":
            if n != 2 { return "Requires exactly 2 groups (you have \(n))" }
            if !paired { return "Requires paired/matched data" }
        case "kruskal_wallis":
            if n < 3 { return "Requires 3+ groups (you have \(n))" }
            if paired { return "Requires independent groups" }
        case "friedman":
            if n < 3 { return "Requires 3+ groups (you have \(n))" }
            if !paired { return "Requires paired/repeated measures data" }
        case "chi_square":
            return "Requires contingency table data"
        case "fisher_exact":
            return "Requires 2x2 contingency table data"
        case "chi_square_gof":
            return "Requires observed vs expected frequency data"
        case "mcnemar":
            return "Requires paired categorical data"
        case "pearson":
            if n < 2 { return "Requires XY data with 2+ data points" }
        case "spearman":
            if n < 2 { return "Requires XY data with 2+ data points" }
        case "linear_regression":
            if n < 2 { return "Requires XY data" }
        case "multiple_regression":
            return "Requires multiple predictor variables"
        case "log_rank":
            return "Requires time-to-event survival data"
        case "gehan_wilcoxon":
            return "Requires time-to-event survival data"
        case "cox_ph":
            return "Requires time-to-event survival data with covariates"
        case "one_sample_t":
            break // always applicable
        case "permutation":
            if n < 2 { return "Requires 2+ groups (you have \(n))" }
        case "ks_test":
            break // always applicable
        default:
            break
        }
        return nil
    }

    // MARK: - Decision Path Builder

    private struct DecisionStep {
        let label: String
        let passed: Bool
        let isFinal: Bool
    }

    private func buildDecisionPath(_ checks: DiagnosticChecks, recommendedTest: String?) -> [DecisionStep] {
        var steps: [DecisionStep] = []

        // Step 1: number of groups
        if checks.nGroups == 1 {
            steps.append(DecisionStep(label: "1 group", passed: true, isFinal: false))
            steps.append(DecisionStep(label: "Descriptive statistics only", passed: true, isFinal: true))
            return steps
        } else if checks.nGroups == 2 {
            steps.append(DecisionStep(label: "2 groups", passed: true, isFinal: false))
        } else {
            steps.append(DecisionStep(label: "\(checks.nGroups) groups (3+)", passed: true, isFinal: false))
        }

        // Step 2: paired or independent
        steps.append(DecisionStep(
            label: checks.paired ? "Paired / related" : "Independent",
            passed: true,
            isFinal: false
        ))

        // Step 3: normality
        steps.append(DecisionStep(
            label: checks.allNormal ? "Normal distribution" : "Not normal",
            passed: checks.allNormal,
            isFinal: false
        ))

        // Step 4: equal variance (only if normal + independent)
        if checks.allNormal && !checks.paired {
            steps.append(DecisionStep(
                label: checks.equalVariance ? "Equal variance" : "Unequal variance",
                passed: checks.equalVariance,
                isFinal: false
            ))
        }

        // Final: recommended test
        if let label = recommendedTest {
            let humanLabel = Self.allTests.first(where: { $0.id == label })?.name ?? label
            steps.append(DecisionStep(label: humanLabel, passed: true, isFinal: true))
        }

        return steps
    }

    // MARK: - Load Data

    private func loadRecommendation() async {
        guard let path = table?.dataFilePath, !path.isEmpty else {
            isLoading = false
            return
        }
        do {
            recommendation = try await APIClient.shared.recommendTest(excelPath: path)
        } catch {
            recommendation = nil
        }
        isLoading = false
    }

    // MARK: - Complete Test Catalog

    static let allTests: [StatTestEntry] = [
        // Parametric
        StatTestEntry(
            id: "unpaired_t",
            name: "Unpaired t-test",
            description: "Compare means of 2 independent groups.",
            whenToUse: "Two unrelated groups, continuous outcome, normal data with equal variance.",
            assumptions: ["Normality", "Equal variance", "Independent observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "welch_t",
            name: "Welch's t-test",
            description: "Compare means of 2 independent groups without assuming equal variance.",
            whenToUse: "Two unrelated groups, normal data but variances may differ.",
            assumptions: ["Normality", "Independent observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "paired_t",
            name: "Paired t-test",
            description: "Compare means of 2 related or matched groups.",
            whenToUse: "Before/after measurements, matched pairs, or repeated measures on same subjects.",
            assumptions: ["Normally distributed differences", "Paired observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "anova",
            name: "One-way ANOVA",
            description: "Compare means of 3 or more independent groups.",
            whenToUse: "Three+ unrelated groups with a single factor. Use Tukey HSD for posthoc.",
            assumptions: ["Normality", "Equal variance", "Independent observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "welch_anova",
            name: "Welch's ANOVA",
            description: "Compare means of 3 or more independent groups with unequal variance.",
            whenToUse: "Three+ groups when Levene's test rejects equal variance. Use Games-Howell for posthoc.",
            assumptions: ["Normality", "Independent observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "repeated_measures_anova",
            name: "Repeated measures ANOVA",
            description: "Compare means of 3 or more related groups (same subjects measured multiple times).",
            whenToUse: "Longitudinal data or multiple conditions on same subjects.",
            assumptions: ["Normality", "Sphericity", "Paired observations"],
            category: .parametric
        ),
        StatTestEntry(
            id: "two_way_anova",
            name: "Two-way ANOVA",
            description: "Test effects of two factors and their interaction.",
            whenToUse: "Data classified by two categorical factors (e.g., drug x dose).",
            assumptions: ["Normality", "Equal variance", "Independent observations"],
            category: .parametric
        ),

        // Nonparametric
        StatTestEntry(
            id: "mann_whitney",
            name: "Mann-Whitney U",
            description: "Compare distributions of 2 independent groups.",
            whenToUse: "Alternative to unpaired t-test when normality is violated.",
            assumptions: ["Independent observations", "Similar distribution shapes"],
            category: .nonparametric
        ),
        StatTestEntry(
            id: "wilcoxon",
            name: "Wilcoxon signed-rank",
            description: "Compare 2 related groups using ranks.",
            whenToUse: "Alternative to paired t-test when differences are not normally distributed.",
            assumptions: ["Paired observations", "Symmetric difference distribution"],
            category: .nonparametric
        ),
        StatTestEntry(
            id: "kruskal_wallis",
            name: "Kruskal-Wallis",
            description: "Compare distributions of 3 or more independent groups.",
            whenToUse: "Alternative to one-way ANOVA when normality is violated. Use Dunn's test for posthoc.",
            assumptions: ["Independent observations", "Ordinal or continuous data"],
            category: .nonparametric
        ),
        StatTestEntry(
            id: "friedman",
            name: "Friedman test",
            description: "Compare 3 or more related groups using ranks.",
            whenToUse: "Alternative to repeated measures ANOVA for non-normal data.",
            assumptions: ["Paired/repeated observations", "Ordinal or continuous data"],
            category: .nonparametric
        ),

        // Categorical
        StatTestEntry(
            id: "chi_square",
            name: "Chi-square test of independence",
            description: "Test association between two categorical variables.",
            whenToUse: "Contingency table with expected counts >= 5 in each cell.",
            assumptions: ["Independent observations", "Expected counts >= 5"],
            category: .categorical
        ),
        StatTestEntry(
            id: "fisher_exact",
            name: "Fisher's exact test",
            description: "Like chi-square but exact, for small sample sizes.",
            whenToUse: "2x2 contingency tables with small expected counts.",
            assumptions: ["Independent observations", "2x2 table"],
            category: .categorical
        ),
        StatTestEntry(
            id: "chi_square_gof",
            name: "Chi-square goodness of fit",
            description: "Test if observed frequencies match expected distribution.",
            whenToUse: "One categorical variable, comparing to theoretical distribution.",
            assumptions: ["Independent observations", "Expected counts >= 5"],
            category: .categorical
        ),
        StatTestEntry(
            id: "mcnemar",
            name: "McNemar's test",
            description: "Paired categorical data (before/after on same subjects).",
            whenToUse: "Matched pairs with binary outcome (e.g., success/failure before and after treatment).",
            assumptions: ["Paired observations", "Binary outcome"],
            category: .categorical
        ),

        // Correlation & Regression
        StatTestEntry(
            id: "pearson",
            name: "Pearson correlation",
            description: "Measure linear relationship between two continuous variables.",
            whenToUse: "Both variables are continuous, normally distributed, and linearly related.",
            assumptions: ["Normality", "Linear relationship", "Continuous data"],
            category: .correlation
        ),
        StatTestEntry(
            id: "spearman",
            name: "Spearman correlation",
            description: "Measure monotonic relationship between variables.",
            whenToUse: "Nonparametric alternative to Pearson. Works with ordinal data or non-linear monotonic trends.",
            assumptions: ["Monotonic relationship", "Ordinal or continuous data"],
            category: .correlation
        ),
        StatTestEntry(
            id: "linear_regression",
            name: "Simple linear regression",
            description: "Predict Y from X. Returns slope, intercept, and R-squared.",
            whenToUse: "Model a linear relationship between a predictor and outcome.",
            assumptions: ["Linearity", "Normality of residuals", "Homoscedasticity"],
            category: .correlation
        ),
        StatTestEntry(
            id: "multiple_regression",
            name: "Multiple regression",
            description: "Predict Y from multiple X variables.",
            whenToUse: "Model outcome from several predictors simultaneously.",
            assumptions: ["Linearity", "No multicollinearity", "Normal residuals"],
            category: .correlation
        ),

        // Survival
        StatTestEntry(
            id: "log_rank",
            name: "Log-rank test",
            description: "Compare survival curves between groups.",
            whenToUse: "Time-to-event data with two or more groups and possible censoring.",
            assumptions: ["Non-informative censoring", "Proportional hazards"],
            category: .survival
        ),
        StatTestEntry(
            id: "gehan_wilcoxon",
            name: "Gehan-Wilcoxon test",
            description: "Like log-rank but weights early events more heavily.",
            whenToUse: "When early differences between survival curves are more important.",
            assumptions: ["Non-informative censoring"],
            category: .survival
        ),
        StatTestEntry(
            id: "cox_ph",
            name: "Cox proportional hazards",
            description: "Regression model for survival data with covariates.",
            whenToUse: "Survival analysis adjusting for multiple predictors.",
            assumptions: ["Proportional hazards", "Non-informative censoring"],
            category: .survival
        ),

        // Other
        StatTestEntry(
            id: "one_sample_t",
            name: "One-sample t-test",
            description: "Compare a group mean to a known or hypothesized value.",
            whenToUse: "Testing whether a sample mean differs from a specific number (e.g., 0, 100).",
            assumptions: ["Normality", "Continuous data"],
            category: .other
        ),
        StatTestEntry(
            id: "permutation",
            name: "Permutation test",
            description: "Distribution-free test using resampling.",
            whenToUse: "When parametric assumptions are questionable and exact distribution-free inference is desired.",
            assumptions: ["Exchangeability under null hypothesis"],
            category: .other
        ),
        StatTestEntry(
            id: "ks_test",
            name: "Kolmogorov-Smirnov test",
            description: "Compare two distributions or test normality.",
            whenToUse: "Testing whether a sample follows a specific distribution, or comparing two samples.",
            assumptions: ["Continuous data"],
            category: .other
        ),
    ]
}
