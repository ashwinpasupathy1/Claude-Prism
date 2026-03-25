// StatsTestCatalog.swift — Textbook-level mathematical descriptions
// for every statistical test in the Stats Wiki.

import Foundation

// MARK: - Model

struct StatsTestDetail: Identifiable {
    let id: String
    let name: String
    let aliases: [String]
    let hypotheses: String
    let testStatistic: String
    let distribution: String
    let assumptions: [String]
    let whenToUse: String
    let whenNotToUse: String
    let notes: String
    let references: [String]
}

// MARK: - Catalog

enum StatsTestCatalog {

    /// Look up the full mathematical detail for a test by its id.
    static func detail(for id: String) -> StatsTestDetail? {
        all.first { $0.id == id }
    }

    // MARK: Complete catalog

    static let all: [StatsTestDetail] = [

        // ───────────────────────────────────────────────
        // 1. Unpaired t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "unpaired_t",
            name: "Unpaired (Independent) t-test",
            aliases: ["Student's t-test", "Two-sample t-test"],
            hypotheses: """
                H\u{2080}: \u{03BC}\u{2081} = \u{03BC}\u{2082}
                H\u{2081}: \u{03BC}\u{2081} \u{2260} \u{03BC}\u{2082}
                """,
            testStatistic: """
                t = (x\u{0305}\u{2081} \u{2212} x\u{0305}\u{2082}) / \u{221A}(s\u{00B2}p (1/n\u{2081} + 1/n\u{2082}))

                where the pooled variance is:
                s\u{00B2}p = ((n\u{2081}\u{2212}1)s\u{2081}\u{00B2} + (n\u{2082}\u{2212}1)s\u{2082}\u{00B2}) / (n\u{2081} + n\u{2082} \u{2212} 2)
                """,
            distribution: "t-distribution with df = n\u{2081} + n\u{2082} \u{2212} 2",
            assumptions: [
                "Observations are independent",
                "Both populations are normally distributed",
                "Equal variances in both groups (homoscedasticity)"
            ],
            whenToUse: "Comparing means of two independent groups with a continuous outcome when normality and equal variance hold.",
            whenNotToUse: "When variances are unequal (use Welch's t-test), data are non-normal (use Mann-Whitney U), or you have paired/matched data (use paired t-test).",
            notes: "The pooled variance estimate gives more power than Welch's when the equal-variance assumption is met. Refraction automatically uses Welch's when Levene's test rejects equal variance.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 2. Welch's t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "welch_t",
            name: "Welch's t-test",
            aliases: ["Unequal variance t-test"],
            hypotheses: """
                H\u{2080}: \u{03BC}\u{2081} = \u{03BC}\u{2082}
                H\u{2081}: \u{03BC}\u{2081} \u{2260} \u{03BC}\u{2082}
                """,
            testStatistic: """
                t = (x\u{0305}\u{2081} \u{2212} x\u{0305}\u{2082}) / \u{221A}(s\u{2081}\u{00B2}/n\u{2081} + s\u{2082}\u{00B2}/n\u{2082})

                Welch-Satterthwaite degrees of freedom:
                df = (s\u{2081}\u{00B2}/n\u{2081} + s\u{2082}\u{00B2}/n\u{2082})\u{00B2} / ((s\u{2081}\u{00B2}/n\u{2081})\u{00B2}/(n\u{2081}\u{2212}1) + (s\u{2082}\u{00B2}/n\u{2082})\u{00B2}/(n\u{2082}\u{2212}1))
                """,
            distribution: "t-distribution with Welch-Satterthwaite adjusted df (not necessarily integer)",
            assumptions: [
                "Observations are independent",
                "Both populations are normally distributed"
            ],
            whenToUse: "Comparing means of two independent groups when variances may differ. This is the default two-sample test in many modern packages.",
            whenNotToUse: "When data are non-normal (use Mann-Whitney U) or paired (use paired t-test). When variances are known to be equal, the pooled t-test has slightly more power.",
            notes: "Welch's t-test does NOT assume equal variances. The degrees of freedom are typically non-integer and are rounded down for table look-up. Many statisticians recommend always using Welch's t-test instead of Student's.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 3. Paired t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "paired_t",
            name: "Paired t-test",
            aliases: ["Dependent t-test", "Matched-pairs t-test"],
            hypotheses: """
                H\u{2080}: \u{03BC}d = 0  (where d = paired differences)
                H\u{2081}: \u{03BC}d \u{2260} 0
                """,
            testStatistic: """
                t = d\u{0305} / (sd / \u{221A}n)

                where d\u{0305} = mean of differences,
                sd = standard deviation of differences,
                n = number of pairs
                """,
            distribution: "t-distribution with df = n \u{2212} 1",
            assumptions: [
                "Observations are paired (matched)",
                "Differences are normally distributed",
                "Differences are independent of each other"
            ],
            whenToUse: "Comparing two measurements on the same subjects (before/after, left/right) or on matched pairs.",
            whenNotToUse: "When groups are independent (use unpaired t-test) or differences are non-normal (use Wilcoxon signed-rank test).",
            notes: "The paired t-test works on the differences, not the raw values. It is more powerful than the unpaired test when pairing is effective because it controls for between-subject variability.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 4. One-way ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "anova",
            name: "One-way ANOVA",
            aliases: ["Analysis of variance", "F-test for k groups"],
            hypotheses: """
                H\u{2080}: \u{03BC}\u{2081} = \u{03BC}\u{2082} = \u{2026} = \u{03BC}k
                H\u{2081}: At least one \u{03BC}i differs
                """,
            testStatistic: """
                F = MS_between / MS_within

                SS_between = \u{03A3} n\u{1D62}(x\u{0305}\u{1D62} \u{2212} x\u{0305})\u{00B2}
                SS_within  = \u{03A3}\u{03A3} (x\u{1D62}j \u{2212} x\u{0305}\u{1D62})\u{00B2}
                MS_between = SS_between / (k \u{2212} 1)
                MS_within  = SS_within / (N \u{2212} k)
                """,
            distribution: "F-distribution with df\u{2081} = k \u{2212} 1, df\u{2082} = N \u{2212} k",
            assumptions: [
                "Observations are independent",
                "Each group is normally distributed",
                "Equal variances across groups (homoscedasticity)"
            ],
            whenToUse: "Comparing means of three or more independent groups. Follow up with a posthoc test (e.g. Tukey HSD) to identify which pairs differ.",
            whenNotToUse: "When variances are unequal (use Welch's ANOVA), data are non-normal (use Kruskal-Wallis), or observations are paired (use repeated measures ANOVA).",
            notes: "ANOVA only tells you that at least one group differs; it does not tell you which ones. Always follow a significant ANOVA with a posthoc test. Refraction uses Tukey HSD by default.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 5. Welch's ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "welch_anova",
            name: "Welch's ANOVA",
            aliases: ["Welch's F-test"],
            hypotheses: """
                H\u{2080}: \u{03BC}\u{2081} = \u{03BC}\u{2082} = \u{2026} = \u{03BC}k
                H\u{2081}: At least one \u{03BC}i differs
                """,
            testStatistic: """
                Uses weighted group means and a modified F-statistic
                that does not pool variances. Weights: w\u{1D62} = n\u{1D62} / s\u{1D62}\u{00B2}

                The test statistic follows an approximate F-distribution
                with adjusted degrees of freedom.
                """,
            distribution: "Approximate F-distribution with adjusted degrees of freedom",
            assumptions: [
                "Observations are independent",
                "Each group is normally distributed"
            ],
            whenToUse: "Comparing means of three or more independent groups when Levene's test indicates unequal variances. Follow up with Games-Howell for posthoc comparisons.",
            whenNotToUse: "When data are non-normal (use Kruskal-Wallis) or when observations are paired/repeated (use repeated measures ANOVA).",
            notes: "Welch's ANOVA does NOT assume equal variances. It reduces to Welch's t-test for k = 2. Games-Howell is the recommended posthoc test because it also does not assume equal variances.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 6. Repeated measures ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "repeated_measures_anova",
            name: "Repeated Measures ANOVA",
            aliases: ["Within-subjects ANOVA"],
            hypotheses: """
                H\u{2080}: \u{03BC}\u{2081} = \u{03BC}\u{2082} = \u{2026} = \u{03BC}k  (across conditions)
                H\u{2081}: At least one condition mean differs
                """,
            testStatistic: """
                F = MS_conditions / MS_error

                Total variance is partitioned into:
                SS_total = SS_between_subjects + SS_conditions + SS_error
                df_conditions = k \u{2212} 1
                df_error = (n \u{2212} 1)(k \u{2212} 1)
                """,
            distribution: "F-distribution with df\u{2081} = k \u{2212} 1, df\u{2082} = (n \u{2212} 1)(k \u{2212} 1)",
            assumptions: [
                "Normally distributed data in each condition",
                "Sphericity: equal variances of differences between all pairs of conditions (Mauchly's test)",
                "Observations within subjects are related"
            ],
            whenToUse: "Comparing three or more measurements on the same subjects across time or conditions (e.g. pre, during, post treatment).",
            whenNotToUse: "When observations are independent (use one-way ANOVA) or data are non-normal (use Friedman test).",
            notes: "When sphericity is violated (Mauchly's test significant), apply Greenhouse-Geisser or Huynh-Feldt correction to the degrees of freedom. Refraction applies Greenhouse-Geisser automatically when needed.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 7. Two-way ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "two_way_anova",
            name: "Two-way ANOVA",
            aliases: ["Factorial ANOVA", "Two-factor ANOVA"],
            hypotheses: """
                H\u{2080}A: No main effect of Factor A
                H\u{2080}B: No main effect of Factor B
                H\u{2080}AB: No interaction between A and B
                """,
            testStatistic: """
                Three separate F-tests (Type III SS):

                F_A  = MS_A / MS_error      (main effect of A)
                F_B  = MS_B / MS_error      (main effect of B)
                F_AB = MS_AB / MS_error     (interaction)

                Each SS is computed after removing all other effects
                (Type III sum of squares).
                """,
            distribution: """
                F_A:  F with df\u{2081} = a \u{2212} 1, df\u{2082} = N \u{2212} ab
                F_B:  F with df\u{2081} = b \u{2212} 1, df\u{2082} = N \u{2212} ab
                F_AB: F with df\u{2081} = (a\u{2212}1)(b\u{2212}1), df\u{2082} = N \u{2212} ab
                """,
            assumptions: [
                "Observations are independent",
                "Normality within each cell",
                "Equal variances across cells (homoscedasticity)"
            ],
            whenToUse: "When data are classified by two categorical factors and you want to test main effects and their interaction (e.g. drug \u{00D7} dose).",
            whenNotToUse: "When there is only one factor (use one-way ANOVA) or when cell sizes are very unbalanced with non-normal data.",
            notes: "Refraction uses Type III sum of squares so each effect is tested after removing all other effects. Always examine the interaction first: if significant, main effects must be interpreted cautiously.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 8. One-sample t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "one_sample_t",
            name: "One-sample t-test",
            aliases: ["Single-sample t-test"],
            hypotheses: """
                H\u{2080}: \u{03BC} = \u{03BC}\u{2080}  (population mean equals a hypothesized value)
                H\u{2081}: \u{03BC} \u{2260} \u{03BC}\u{2080}
                """,
            testStatistic: """
                t = (x\u{0305} \u{2212} \u{03BC}\u{2080}) / (s / \u{221A}n)

                where x\u{0305} = sample mean,
                \u{03BC}\u{2080} = hypothesized value,
                s = sample standard deviation
                """,
            distribution: "t-distribution with df = n \u{2212} 1",
            assumptions: [
                "Observations are independent",
                "Data are normally distributed (or n is large enough for CLT)"
            ],
            whenToUse: "Testing whether a sample mean differs from a known or hypothesized value (e.g. testing if mean = 0, mean = 100).",
            whenNotToUse: "When data are severely non-normal with small n (use Wilcoxon signed-rank against the hypothesized median) or when comparing two groups (use two-sample tests).",
            notes: "The default hypothesized value in Refraction is 0. You can change it in the analysis configuration. For large n (\u{2265} 30), the test is robust to moderate non-normality.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 9. Mann-Whitney U test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "mann_whitney",
            name: "Mann-Whitney U test",
            aliases: ["Wilcoxon rank-sum test", "Mann-Whitney-Wilcoxon"],
            hypotheses: """
                H\u{2080}: The two groups have the same distribution
                H\u{2081}: The distributions differ (one group tends to have larger values)
                """,
            testStatistic: """
                U = n\u{2081}n\u{2082} + n\u{2081}(n\u{2081}+1)/2 \u{2212} R\u{2081}

                where R\u{2081} = sum of ranks in group 1
                (after ranking all observations together).

                For large samples, use normal approximation:
                z = (U \u{2212} n\u{2081}n\u{2082}/2) / \u{221A}(n\u{2081}n\u{2082}(n\u{2081}+n\u{2082}+1)/12)
                """,
            distribution: "Exact tables for small n; normal approximation for large n",
            assumptions: [
                "Observations are independent",
                "Ordinal or continuous data",
                "Similar distribution shapes (for interpreting as a location shift)"
            ],
            whenToUse: "Comparing two independent groups when data are not normally distributed, are ordinal, or have outliers that would distort a t-test.",
            whenNotToUse: "When data are paired (use Wilcoxon signed-rank) or when there are 3+ groups (use Kruskal-Wallis).",
            notes: "Ties are handled by assigning the average rank to tied observations. The tie correction adjusts the variance in the z-approximation. This test is often called the Wilcoxon rank-sum test, which is mathematically equivalent.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 10. Wilcoxon signed-rank test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "wilcoxon",
            name: "Wilcoxon Signed-Rank test",
            aliases: ["Wilcoxon matched-pairs signed-rank test"],
            hypotheses: """
                H\u{2080}: Median of differences = 0
                H\u{2081}: Median of differences \u{2260} 0
                """,
            testStatistic: """
                1. Compute differences d\u{1D62} = x\u{1D62} \u{2212} y\u{1D62}
                2. Discard zeros, rank |d\u{1D62}|
                3. Sum ranks of positive differences: T\u{207A}
                4. Sum ranks of negative differences: T\u{207B}
                5. T = min(T\u{207A}, T\u{207B})
                """,
            distribution: "Exact tables for small n; normal approximation for n > 25",
            assumptions: [
                "Paired observations",
                "Differences are symmetric around the median",
                "Continuous or ordinal data"
            ],
            whenToUse: "Comparing two related measurements when the paired differences are not normally distributed.",
            whenNotToUse: "When groups are independent (use Mann-Whitney U) or when differences are normal (paired t-test is more powerful).",
            notes: "Pairs with zero difference are discarded, which reduces the effective sample size. For very small n (< 6), the test has limited power.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 11. Kruskal-Wallis test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "kruskal_wallis",
            name: "Kruskal-Wallis test",
            aliases: ["Kruskal-Wallis H test", "Kruskal-Wallis one-way ANOVA by ranks"],
            hypotheses: """
                H\u{2080}: All k populations have the same distribution
                H\u{2081}: At least one population differs
                """,
            testStatistic: """
                H = (12 / N(N+1)) \u{03A3}(R\u{1D62}\u{00B2} / n\u{1D62}) \u{2212} 3(N+1)

                where R\u{1D62} = sum of ranks in group i,
                N = total number of observations,
                n\u{1D62} = number in group i.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (for large samples)",
            assumptions: [
                "Observations are independent",
                "Ordinal or continuous data",
                "Similar distribution shapes across groups"
            ],
            whenToUse: "Comparing three or more independent groups when data are not normally distributed. Follow up with Dunn's test for pairwise comparisons.",
            whenNotToUse: "When data are paired/repeated (use Friedman test) or when data are normal with equal variances (one-way ANOVA is more powerful).",
            notes: "This is the nonparametric analogue of one-way ANOVA. A tie correction factor is applied when there are tied ranks. Refraction uses Dunn's test with Bonferroni or Holm correction for posthoc comparisons.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 12. Friedman test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "friedman",
            name: "Friedman test",
            aliases: ["Friedman two-way ANOVA by ranks"],
            hypotheses: """
                H\u{2080}: All k treatments have the same effect
                H\u{2081}: At least one treatment differs
                """,
            testStatistic: """
                \u{03C7}\u{00B2}F = (12 / bk(k+1)) \u{03A3}R\u{2C7C}\u{00B2} \u{2212} 3b(k+1)

                where b = number of blocks (subjects),
                k = number of treatments (conditions),
                R\u{2C7C} = sum of ranks for treatment j.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (for large b or k)",
            assumptions: [
                "Data are paired/repeated (blocked by subject)",
                "Ordinal or continuous data",
                "Rankings within each block are independent"
            ],
            whenToUse: "Comparing three or more related groups (same subjects across conditions) when data are not normally distributed.",
            whenNotToUse: "When groups are independent (use Kruskal-Wallis) or when data meet normality and sphericity (repeated measures ANOVA is more powerful).",
            notes: "This is the nonparametric analogue of repeated measures ANOVA. Data are ranked within each subject (block) independently.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 13. Chi-square test of independence
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "chi_square",
            name: "Chi-square test of independence",
            aliases: ["Pearson's chi-square test", "\u{03C7}\u{00B2} test"],
            hypotheses: """
                H\u{2080}: The two categorical variables are independent
                H\u{2081}: The two variables are associated
                """,
            testStatistic: """
                \u{03C7}\u{00B2} = \u{03A3}\u{03A3} (O\u{1D62}\u{2C7C} \u{2212} E\u{1D62}\u{2C7C})\u{00B2} / E\u{1D62}\u{2C7C}

                where E\u{1D62}\u{2C7C} = (row total \u{00D7} column total) / N
                O\u{1D62}\u{2C7C} = observed count in cell (i, j)
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = (r \u{2212} 1)(c \u{2212} 1)",
            assumptions: [
                "Observations are independent",
                "Expected count \u{2265} 5 in each cell (rule of thumb)",
                "Data are counts (not percentages or rates)"
            ],
            whenToUse: "Testing whether two categorical variables are associated in a contingency table, when all expected counts are at least 5.",
            whenNotToUse: "When expected counts are small (use Fisher's exact test for 2\u{00D7}2 tables) or when data are paired (use McNemar's test).",
            notes: "Yates' continuity correction is sometimes applied for 2\u{00D7}2 tables but is conservative. Refraction reports the uncorrected \u{03C7}\u{00B2} by default and falls back to Fisher's exact test when expected counts are too small.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 14. Fisher's exact test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "fisher_exact",
            name: "Fisher's exact test",
            aliases: ["Fisher-Irwin test"],
            hypotheses: """
                H\u{2080}: The two variables are independent (odds ratio = 1)
                H\u{2081}: The two variables are associated (odds ratio \u{2260} 1)
                """,
            testStatistic: """
                For a 2\u{00D7}2 table:
                \u{250C}\u{2500}\u{2500}\u{2500}\u{252C}\u{2500}\u{2500}\u{2500}\u{2510}
                \u{2502} a \u{2502} b \u{2502}
                \u{251C}\u{2500}\u{2500}\u{2500}\u{253C}\u{2500}\u{2500}\u{2500}\u{2524}
                \u{2502} c \u{2502} d \u{2502}
                \u{2514}\u{2500}\u{2500}\u{2500}\u{2534}\u{2500}\u{2500}\u{2500}\u{2518}

                p = (a+b)!(c+d)!(a+c)!(b+d)! / (N! a! b! c! d!)

                Sum probabilities for all tables as extreme or more
                extreme than the observed, given fixed marginals.
                """,
            distribution: "Hypergeometric distribution (exact, not asymptotic)",
            assumptions: [
                "Observations are independent",
                "Fixed marginal totals (or conditioned on them)"
            ],
            whenToUse: "Testing association in a 2\u{00D7}2 contingency table, especially when sample sizes are small or expected counts fall below 5.",
            whenNotToUse: "For larger tables (r\u{00D7}c with r > 2 or c > 2) where computation may be expensive, or when the chi-square approximation is adequate.",
            notes: "Fisher's exact test computes exact probabilities rather than relying on the chi-square approximation. It is always valid but is most useful when the sample is small. For large samples, it gives results very close to the chi-square test.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 15. Chi-square goodness of fit
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "chi_square_gof",
            name: "Chi-square goodness of fit",
            aliases: ["One-sample chi-square test"],
            hypotheses: """
                H\u{2080}: Observed frequencies match the expected distribution
                H\u{2081}: Observed frequencies differ from expected
                """,
            testStatistic: """
                \u{03C7}\u{00B2} = \u{03A3} (O\u{1D62} \u{2212} E\u{1D62})\u{00B2} / E\u{1D62}

                where O\u{1D62} = observed count in category i,
                E\u{1D62} = expected count in category i.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (or k \u{2212} 1 \u{2212} p if p parameters were estimated from the data)",
            assumptions: [
                "Observations are independent",
                "Expected count \u{2265} 5 in each category",
                "Data are counts"
            ],
            whenToUse: "Testing whether observed frequencies match a hypothesized distribution (e.g. equal frequencies, Mendelian ratios).",
            whenNotToUse: "When expected counts are very small (combine categories first) or when testing association between two variables (use chi-square test of independence).",
            notes: "If you estimated parameters from the data to calculate expected values, subtract those from the degrees of freedom. For example, testing normality with estimated mean and SD uses df = k \u{2212} 3.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 16. McNemar's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "mcnemar",
            name: "McNemar's test",
            aliases: ["McNemar's chi-square test"],
            hypotheses: """
                H\u{2080}: The marginal proportions are equal (p\u{2081}. = p.\u{2081})
                H\u{2081}: The marginal proportions differ
                """,
            testStatistic: """
                For a paired 2\u{00D7}2 table:
                \u{250C}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{252C}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2510}
                \u{2502}  a   \u{2502}  b   \u{2502}   (concordant and
                \u{251C}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{253C}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2524}    discordant pairs)
                \u{2502}  c   \u{2502}  d   \u{2502}
                \u{2514}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2534}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2518}

                \u{03C7}\u{00B2} = (b \u{2212} c)\u{00B2} / (b + c)

                Only discordant pairs (b and c) contribute.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = 1",
            assumptions: [
                "Paired observations (before/after on same subjects)",
                "Binary (dichotomous) outcome",
                "b + c (discordant pairs) is sufficiently large (\u{2265} 10)"
            ],
            whenToUse: "Testing whether the proportion of successes changes from before to after an intervention, using matched binary data.",
            whenNotToUse: "When data are not paired (use chi-square test of independence) or when the outcome has more than two levels.",
            notes: "With continuity correction: \u{03C7}\u{00B2} = (|b \u{2212} c| \u{2212} 1)\u{00B2} / (b + c). An exact binomial test on the discordant pairs can be used when b + c is small.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 17. Pearson correlation
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "pearson",
            name: "Pearson correlation coefficient",
            aliases: ["Pearson's r", "Product-moment correlation"],
            hypotheses: """
                H\u{2080}: \u{03C1} = 0  (no linear association)
                H\u{2081}: \u{03C1} \u{2260} 0
                """,
            testStatistic: """
                r = \u{03A3}(x\u{1D62} \u{2212} x\u{0305})(y\u{1D62} \u{2212} y\u{0305}) / \u{221A}(\u{03A3}(x\u{1D62} \u{2212} x\u{0305})\u{00B2} \u{03A3}(y\u{1D62} \u{2212} y\u{0305})\u{00B2})

                Test statistic:
                t = r\u{221A}(n\u{2212}2) / \u{221A}(1 \u{2212} r\u{00B2})
                """,
            distribution: "t-distribution with df = n \u{2212} 2 (for the significance test)",
            assumptions: [
                "Bivariate normality",
                "Linear relationship between variables",
                "Both variables are continuous",
                "No significant outliers"
            ],
            whenToUse: "Measuring the strength and direction of a linear relationship between two continuous, normally distributed variables.",
            whenNotToUse: "When the relationship is non-linear (consider transformation or Spearman), data have outliers (use Spearman), or variables are ordinal (use Spearman).",
            notes: "r ranges from \u{2212}1 (perfect negative) to +1 (perfect positive). r\u{00B2} gives the proportion of variance explained. Pearson's r only captures linear relationships; a non-significant r does not mean no association.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 18. Spearman correlation
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "spearman",
            name: "Spearman rank correlation",
            aliases: ["Spearman's rho", "Spearman's r\u{209B}"],
            hypotheses: """
                H\u{2080}: No monotonic association (\u{03C1}s = 0)
                H\u{2081}: Monotonic association exists (\u{03C1}s \u{2260} 0)
                """,
            testStatistic: """
                r\u{209B} = Pearson r computed on the ranks

                When there are no ties:
                r\u{209B} = 1 \u{2212} 6\u{03A3}d\u{1D62}\u{00B2} / (n(n\u{00B2} \u{2212} 1))

                where d\u{1D62} = rank(x\u{1D62}) \u{2212} rank(y\u{1D62})
                """,
            distribution: "Exact tables for small n; t-approximation with df = n \u{2212} 2 for large n",
            assumptions: [
                "Paired observations",
                "Ordinal or continuous data",
                "Monotonic (not necessarily linear) relationship"
            ],
            whenToUse: "Measuring the strength and direction of a monotonic relationship, especially when data are ordinal, non-normal, or have outliers.",
            whenNotToUse: "When you specifically need to detect only linear relationships and data are bivariate normal (Pearson is more powerful in that case).",
            notes: "Spearman's r\u{209B} is robust to outliers because it operates on ranks. It captures any monotonic relationship, not just linear ones. The shortcut formula (with d\u{1D62}\u{00B2}) only works when there are no tied ranks.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 19. Simple linear regression
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "linear_regression",
            name: "Simple linear regression",
            aliases: ["Ordinary least squares (OLS)", "Linear model"],
            hypotheses: """
                H\u{2080}: \u{03B2}\u{2081} = 0  (slope is zero; X does not predict Y)
                H\u{2081}: \u{03B2}\u{2081} \u{2260} 0
                """,
            testStatistic: """
                y\u{0302} = a + bx

                b = \u{03A3}(x\u{1D62} \u{2212} x\u{0305})(y\u{1D62} \u{2212} y\u{0305}) / \u{03A3}(x\u{1D62} \u{2212} x\u{0305})\u{00B2}
                a = y\u{0305} \u{2212} bx\u{0305}

                R\u{00B2} = SS_regression / SS_total
                F = MS_regression / MS_residual  (df\u{2081} = 1, df\u{2082} = n \u{2212} 2)
                """,
            distribution: "F-distribution with df\u{2081} = 1, df\u{2082} = n \u{2212} 2 for the overall model; t with df = n \u{2212} 2 for the slope",
            assumptions: [
                "Linear relationship between X and Y",
                "Residuals are normally distributed",
                "Homoscedasticity (constant variance of residuals)",
                "Independence of observations"
            ],
            whenToUse: "Modeling a linear relationship between a single predictor and a continuous outcome. Provides slope, intercept, R\u{00B2}, and prediction intervals.",
            whenNotToUse: "When the relationship is non-linear (consider polynomial or nonlinear regression), when there are multiple predictors (use multiple regression), or when residuals are severely non-normal.",
            notes: "R\u{00B2} measures the fraction of variance in Y explained by X. A high R\u{00B2} does not imply causation. Always inspect a residual plot to verify assumptions.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 20. Log-rank test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "log_rank",
            name: "Log-rank test",
            aliases: ["Mantel-Cox test"],
            hypotheses: """
                H\u{2080}: Survival functions are equal across groups
                H\u{2081}: At least one group's survival function differs
                """,
            testStatistic: """
                \u{03C7}\u{00B2} = (\u{03A3}(O\u{2081}\u{2C7C} \u{2212} E\u{2081}\u{2C7C}))\u{00B2} / \u{03A3} Var\u{2081}\u{2C7C}

                At each event time j:
                E\u{2081}\u{2C7C} = d\u{2C7C} \u{00D7} n\u{2081}\u{2C7C} / n\u{2C7C}

                where d\u{2C7C} = total events at time j,
                n\u{2081}\u{2C7C} = at-risk in group 1,
                n\u{2C7C} = total at-risk.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (k = number of groups)",
            assumptions: [
                "Non-informative censoring (censoring is independent of prognosis)",
                "Proportional hazards (hazard ratio is constant over time)"
            ],
            whenToUse: "Comparing survival curves between two or more groups with possibly censored time-to-event data.",
            whenNotToUse: "When hazards are clearly non-proportional (crossing survival curves) \u{2014} consider Gehan-Wilcoxon or stratified analysis. When you need to adjust for covariates, use Cox regression.",
            notes: "The log-rank test gives equal weight to all time points. If early events are more important, the Gehan-Wilcoxon test (which weights earlier events more) may be more appropriate.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 21. Kaplan-Meier estimator
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "kaplan_meier",
            name: "Kaplan-Meier estimator",
            aliases: ["Product-limit estimator", "KM curve"],
            hypotheses: """
                (Descriptive method \u{2014} no hypothesis test per se.
                Use the log-rank test to compare KM curves between groups.)
                """,
            testStatistic: """
                S\u{0302}(t) = \u{220F}(1 \u{2212} d\u{1D62} / n\u{1D62})  for all t\u{1D62} \u{2264} t

                where d\u{1D62} = events at time t\u{1D62},
                n\u{1D62} = number at risk just before t\u{1D62}.

                Greenwood variance:
                Var(S\u{0302}(t)) = S\u{0302}(t)\u{00B2} \u{03A3} d\u{1D62} / (n\u{1D62}(n\u{1D62} \u{2212} d\u{1D62}))
                """,
            distribution: "Pointwise confidence intervals use log or log-log transformation",
            assumptions: [
                "Non-informative censoring",
                "Event times are independent",
                "Survival probability depends only on time since origin"
            ],
            whenToUse: "Estimating the survival function from censored time-to-event data. Produces the classic step-function survival curve.",
            whenNotToUse: "When you need to adjust for covariates (use Cox regression) or when there is no censoring (simpler methods suffice).",
            notes: "Censored observations are indicated by a + or tick on the curve. The KM estimator handles right-censoring naturally. Median survival is the time at which S\u{0302}(t) = 0.5.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 22. Tukey HSD
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "tukey_hsd",
            name: "Tukey's Honest Significant Difference (HSD)",
            aliases: ["Tukey-Kramer test", "Tukey's range test"],
            hypotheses: """
                For each pair (i, j):
                H\u{2080}: \u{03BC}\u{1D62} = \u{03BC}\u{2C7C}
                H\u{2081}: \u{03BC}\u{1D62} \u{2260} \u{03BC}\u{2C7C}
                """,
            testStatistic: """
                q = (x\u{0305}\u{1D62} \u{2212} x\u{0305}\u{2C7C}) / \u{221A}(MS_within / n)

                For unequal group sizes (Tukey-Kramer):
                q = (x\u{0305}\u{1D62} \u{2212} x\u{0305}\u{2C7C}) / \u{221A}(MS_within \u{00D7} (1/n\u{1D62} + 1/n\u{2C7C}) / 2)
                """,
            distribution: "Studentized range distribution with k groups and df = N \u{2212} k",
            assumptions: [
                "One-way ANOVA assumptions (normality, equal variance, independence)",
                "All pairwise comparisons are of interest"
            ],
            whenToUse: "Following a significant one-way ANOVA to identify which specific pairs of group means differ, while controlling the family-wise error rate.",
            whenNotToUse: "When variances are unequal (use Games-Howell), when only comparisons to a control are needed (use Dunnett's), or after Kruskal-Wallis (use Dunn's test).",
            notes: "Tukey HSD controls the family-wise Type I error rate at \u{03B1} simultaneously for all pairwise comparisons. It is the most common posthoc test in biology and is the default in Refraction.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 23. Dunn's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "dunns_test",
            name: "Dunn's test",
            aliases: ["Dunn's multiple comparison test"],
            hypotheses: """
                For each pair (i, j):
                H\u{2080}: Group i and group j have the same distribution
                H\u{2081}: The distributions differ
                """,
            testStatistic: """
                z = (R\u{0305}\u{1D62} \u{2212} R\u{0305}\u{2C7C}) / \u{221A}((N(N+1)/12)(1/n\u{1D62} + 1/n\u{2C7C}))

                where R\u{0305}\u{1D62} = mean rank for group i,
                N = total sample size.

                Apply Bonferroni or Holm correction to the p-values.
                """,
            distribution: "Standard normal (z) for each pairwise comparison",
            assumptions: [
                "Data are ranked (follows Kruskal-Wallis)",
                "Groups are independent"
            ],
            whenToUse: "Following a significant Kruskal-Wallis test to identify which pairs of groups differ.",
            whenNotToUse: "After a parametric ANOVA (use Tukey HSD instead) or when data are paired.",
            notes: "Dunn's test uses the same ranking from the Kruskal-Wallis test. Refraction applies either Bonferroni or Holm-Bonferroni correction to control the family-wise error rate.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 24. Dunnett's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "dunnetts_test",
            name: "Dunnett's test",
            aliases: ["Dunnett's many-to-one comparisons"],
            hypotheses: """
                For each treatment i vs control:
                H\u{2080}: \u{03BC}\u{1D62} = \u{03BC}_control
                H\u{2081}: \u{03BC}\u{1D62} \u{2260} \u{03BC}_control
                """,
            testStatistic: """
                t = (x\u{0305}\u{1D62} \u{2212} x\u{0305}_control) / \u{221A}(MS_within (1/n\u{1D62} + 1/n_control))

                Critical values come from the multivariate t-distribution
                accounting for the correlation structure between comparisons.
                """,
            distribution: "Multivariate t-distribution with df = N \u{2212} k and k \u{2212} 1 comparisons",
            assumptions: [
                "One-way ANOVA assumptions (normality, equal variance, independence)",
                "Only comparisons to a single control group are of interest"
            ],
            whenToUse: "Comparing multiple treatment groups against a single control, while controlling the family-wise error rate for only those specific comparisons.",
            whenNotToUse: "When all pairwise comparisons are needed (use Tukey HSD) or after a nonparametric test.",
            notes: "Dunnett's test is more powerful than Tukey for control-vs-treatment comparisons because it makes fewer comparisons. In Refraction, set the control group in the analysis configuration.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 25. Games-Howell
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "games_howell",
            name: "Games-Howell test",
            aliases: ["Games-Howell posthoc"],
            hypotheses: """
                For each pair (i, j):
                H\u{2080}: \u{03BC}\u{1D62} = \u{03BC}\u{2C7C}
                H\u{2081}: \u{03BC}\u{1D62} \u{2260} \u{03BC}\u{2C7C}
                """,
            testStatistic: """
                q = (x\u{0305}\u{1D62} \u{2212} x\u{0305}\u{2C7C}) / \u{221A}((s\u{1D62}\u{00B2}/n\u{1D62} + s\u{2C7C}\u{00B2}/n\u{2C7C}) / 2)

                Welch-Satterthwaite df for each pair:
                df = (s\u{1D62}\u{00B2}/n\u{1D62} + s\u{2C7C}\u{00B2}/n\u{2C7C})\u{00B2} / ((s\u{1D62}\u{00B2}/n\u{1D62})\u{00B2}/(n\u{1D62}\u{2212}1) + (s\u{2C7C}\u{00B2}/n\u{2C7C})\u{00B2}/(n\u{2C7C}\u{2212}1))
                """,
            distribution: "Studentized range distribution with pair-specific df",
            assumptions: [
                "Normality within each group",
                "Groups are independent"
            ],
            whenToUse: "Following Welch's ANOVA (or when variances are unequal) to identify which pairs differ. Does NOT assume equal variances.",
            whenNotToUse: "When variances are equal (Tukey HSD is more powerful) or after a nonparametric test.",
            notes: "Games-Howell is like Tukey HSD but uses separate variance estimates and Welch-Satterthwaite df for each pair. It is the recommended posthoc test when Levene's test rejects equal variances.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 26. Cohen's d
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "cohens_d",
            name: "Cohen's d (effect size)",
            aliases: ["Standardized mean difference"],
            hypotheses: """
                (Effect size measure \u{2014} no hypothesis test.
                Used to quantify the magnitude of a difference.)
                """,
            testStatistic: """
                d = (x\u{0305}\u{2081} \u{2212} x\u{0305}\u{2082}) / sp

                where sp = \u{221A}(((n\u{2081}\u{2212}1)s\u{2081}\u{00B2} + (n\u{2082}\u{2212}1)s\u{2082}\u{00B2}) / (n\u{2081} + n\u{2082} \u{2212} 2))

                Conventional thresholds (Cohen, 1988):
                  Small:   d = 0.2
                  Medium:  d = 0.5
                  Large:   d = 0.8
                """,
            distribution: "Not a test statistic; no reference distribution",
            assumptions: [
                "Meaningful to compare means (continuous data)",
                "Pooled SD is an appropriate measure of spread"
            ],
            whenToUse: "Reporting the practical significance of a difference between two group means, independent of sample size.",
            whenNotToUse: "When comparing more than two groups (consider \u{03B7}\u{00B2} or partial \u{03B7}\u{00B2}), or when data are non-normal (consider rank-biserial correlation).",
            notes: "A statistically significant p-value does not imply a large effect. Always report an effect size alongside p-values. Cohen's thresholds are rough guidelines; the meaningful effect size depends on your field.",
            references: [
                "Cohen, J. (1988). Statistical Power Analysis for the Behavioral Sciences, 2nd ed. Erlbaum.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3."
            ]
        ),

        // ───────────────────────────────────────────────
        // Additional tests from the wiki catalog
        // ───────────────────────────────────────────────

        StatsTestDetail(
            id: "multiple_regression",
            name: "Multiple linear regression",
            aliases: ["Multiple regression", "OLS with multiple predictors"],
            hypotheses: """
                H\u{2080}: All slopes are zero (\u{03B2}\u{2081} = \u{03B2}\u{2082} = \u{2026} = 0)
                H\u{2081}: At least one slope is non-zero
                """,
            testStatistic: """
                y\u{0302} = \u{03B2}\u{2080} + \u{03B2}\u{2081}x\u{2081} + \u{03B2}\u{2082}x\u{2082} + \u{2026} + \u{03B2}px\u{209A}

                Overall F = (R\u{00B2}/p) / ((1 \u{2212} R\u{00B2})/(n \u{2212} p \u{2212} 1))
                Individual t\u{1D62} = \u{03B2}\u{0302}\u{1D62} / SE(\u{03B2}\u{0302}\u{1D62})
                """,
            distribution: "F with df\u{2081} = p, df\u{2082} = n \u{2212} p \u{2212} 1 (overall); t with df = n \u{2212} p \u{2212} 1 (per coefficient)",
            assumptions: [
                "Linearity",
                "No multicollinearity among predictors",
                "Normally distributed residuals",
                "Homoscedasticity",
                "Independence of observations"
            ],
            whenToUse: "Predicting a continuous outcome from multiple predictors simultaneously.",
            whenNotToUse: "When predictors are highly correlated (multicollinearity) or when the outcome is binary (use logistic regression).",
            notes: "Check VIF (variance inflation factor) for multicollinearity. Adjusted R\u{00B2} accounts for the number of predictors and is preferred over R\u{00B2} for model comparison.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        StatsTestDetail(
            id: "gehan_wilcoxon",
            name: "Gehan-Wilcoxon test",
            aliases: ["Gehan-Breslow test", "Generalized Wilcoxon test"],
            hypotheses: """
                H\u{2080}: Survival functions are equal across groups
                H\u{2081}: Survival functions differ
                """,
            testStatistic: """
                Like the log-rank test but weights each event time
                by the number at risk n\u{2C7C}, giving more weight to
                early events when sample sizes are largest.

                The test statistic follows a \u{03C7}\u{00B2} distribution.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1",
            assumptions: [
                "Non-informative censoring",
                "Time-to-event data with possible censoring"
            ],
            whenToUse: "Comparing survival curves when early differences are more important than late differences, or when proportional hazards may not hold.",
            whenNotToUse: "When hazards are proportional and all time points are equally important (log-rank test is more standard and powerful).",
            notes: "The Gehan-Wilcoxon test is more sensitive to early survival differences. It is a good complement to the log-rank test. If both agree, the conclusion is robust.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        StatsTestDetail(
            id: "cox_ph",
            name: "Cox proportional hazards regression",
            aliases: ["Cox regression", "Cox model"],
            hypotheses: """
                H\u{2080}: \u{03B2} = 0  (covariate has no effect on hazard)
                H\u{2081}: \u{03B2} \u{2260} 0
                """,
            testStatistic: """
                h(t) = h\u{2080}(t) \u{00D7} exp(\u{03B2}\u{2081}x\u{2081} + \u{03B2}\u{2082}x\u{2082} + \u{2026})

                Hazard ratio: HR = exp(\u{03B2})
                Coefficients estimated by partial likelihood.
                Test using Wald \u{03C7}\u{00B2} or likelihood ratio test.
                """,
            distribution: "\u{03C7}\u{00B2} (Wald or LR) with df = number of covariates",
            assumptions: [
                "Proportional hazards: HR is constant over time",
                "Non-informative censoring",
                "Log-linear relationship between hazard and covariates"
            ],
            whenToUse: "Modeling the effect of one or more covariates on survival time, while allowing for censoring.",
            whenNotToUse: "When the proportional hazards assumption is violated (consider stratified Cox or time-varying coefficients).",
            notes: "The baseline hazard h\u{2080}(t) is left unspecified (semi-parametric). Schoenfeld residuals can diagnose violations of proportional hazards. HR > 1 means increased hazard (worse survival).",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        StatsTestDetail(
            id: "permutation",
            name: "Permutation test",
            aliases: ["Randomization test", "Exact test"],
            hypotheses: """
                H\u{2080}: Group labels are exchangeable (no difference)
                H\u{2081}: Group assignment matters
                """,
            testStatistic: """
                1. Choose a test statistic (e.g. difference in means).
                2. Compute it for the observed data: T_obs.
                3. Randomly permute group labels many times (or enumerate all permutations).
                4. For each permutation, compute the test statistic.
                5. p = proportion of permuted statistics \u{2265} |T_obs|.
                """,
            distribution: "Empirical distribution from permutations (distribution-free)",
            assumptions: [
                "Exchangeability of observations under H\u{2080}",
                "Independent observations"
            ],
            whenToUse: "When parametric assumptions are questionable and you want an exact, distribution-free test. Particularly useful with small samples or unusual distributions.",
            whenNotToUse: "When computational cost is prohibitive (very large n) or when a well-established parametric test is appropriate.",
            notes: "Refraction uses 10,000 permutations by default for approximate p-values. The permutation test makes no distributional assumptions but does assume exchangeability under the null.",
            references: [
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.4."
            ]
        ),

        StatsTestDetail(
            id: "ks_test",
            name: "Kolmogorov-Smirnov test",
            aliases: ["KS test", "K-S test"],
            hypotheses: """
                One-sample: H\u{2080}: Data follow the specified distribution
                Two-sample: H\u{2080}: Both samples come from the same distribution
                """,
            testStatistic: """
                D = max |F_n(x) \u{2212} F\u{2080}(x)|   (one-sample)
                D = max |F\u{2081}(x) \u{2212} F\u{2082}(x)|   (two-sample)

                where F_n(x) = empirical CDF,
                F\u{2080}(x) = theoretical CDF.
                """,
            distribution: "Kolmogorov-Smirnov distribution (exact tables or asymptotic)",
            assumptions: [
                "Continuous data",
                "The reference distribution is fully specified (parameters not estimated from the data)"
            ],
            whenToUse: "Testing whether data follow a specific distribution (e.g. normal) or whether two samples have the same distribution.",
            whenNotToUse: "For testing normality specifically, the Shapiro-Wilk test is more powerful. When parameters are estimated from the data, use the Lilliefors correction.",
            notes: "The KS test is sensitive to any difference in distribution (location, scale, shape) but has less power than specialized tests. The ECDF chart type in Refraction visualizes the empirical distribution that this test is based on.",
            references: [
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.4."
            ]
        ),
    ]
}
