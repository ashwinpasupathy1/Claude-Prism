"""
refraction.core.stats
=====================
Pure statistical computation layer for Refraction.

This module contains all statistical primitives: descriptive statistics,
hypothesis tests, effect sizes, survival analysis, two-way ANOVA, curve
fitting, and p-value helpers.  Chart presentation code lives in
chart_helpers.py; this module is imported by both chart_helpers and the
Plotly spec builders (refraction/specs/).
"""

from __future__ import annotations

import itertools
import math
import warnings
from typing import List, Optional, Sequence, Tuple, Union

import numpy as np
from scipy import stats as sp_stats


# ---------------------------------------------------------------------------
# Descriptive statistics (original stats.py functions)
# ---------------------------------------------------------------------------

def calc_mean(vals: Sequence[float]) -> float:
    """Return the arithmetic mean, or NaN if empty."""
    if len(vals) == 0:
        return float("nan")
    return float(np.mean(vals))


def calc_sd(vals: Sequence[float], ddof: int = 1) -> float:
    """Return sample standard deviation (Bessel-corrected by default).

    Returns 0.0 when n <= ddof to avoid division-by-zero.
    """
    n = len(vals)
    if n <= ddof:
        return 0.0
    return float(np.std(vals, ddof=ddof))


def calc_sem(vals: Sequence[float]) -> float:
    """Return standard error of the mean.

    SEM = SD / sqrt(n).  Returns 0.0 when n < 2.
    """
    n = len(vals)
    if n < 2:
        return 0.0
    sd = calc_sd(vals)
    return sd / math.sqrt(n)


def calc_error(vals: Sequence[float], error_type: str = "sem") -> Tuple[float, float]:
    """Return (mean, error_bar_half_width) for a given error type.

    error_type: "sem", "sd", or "ci95".
    """
    n = len(vals)
    m = calc_mean(vals)
    sd = calc_sd(vals)
    if error_type == "sem":
        return m, sd / math.sqrt(n) if n > 0 else 0.0
    elif error_type == "sd":
        return m, sd
    else:  # ci95
        ci = sp_stats.t.ppf(0.975, df=max(n - 1, 1)) * sd / math.sqrt(max(n, 1))
        return m, float(ci)


def descriptive_stats(vals: Sequence[float]) -> dict:
    """Return a dict of common descriptive statistics for a numeric array.

    Keys: n, mean, sd, sem, min, median, max.
    """
    arr = np.asarray(vals, dtype=float)
    n = len(arr)
    if n == 0:
        nan = float("nan")
        return dict(n=0, mean=nan, sd=nan, sem=nan, min=nan, median=nan, max=nan)
    m = float(np.mean(arr))
    sd = float(np.std(arr, ddof=1)) if n > 1 else float("nan")
    sem = sd / math.sqrt(n) if n > 1 else float("nan")
    return dict(
        n=n,
        mean=m,
        sd=sd,
        sem=sem,
        min=float(np.min(arr)),
        median=float(np.median(arr)),
        max=float(np.max(arr)),
    )


# ---------------------------------------------------------------------------
# Error bar computation (moved from chart_helpers.py)
# ---------------------------------------------------------------------------

def _calc_error(vals, error_type):
    """Return (mean, error_bar_half_width) for a given error type."""
    n = len(vals)
    m = float(np.mean(vals))
    s = float(np.std(vals, ddof=1)) if n > 1 else 0.0
    if error_type == "sem":
        return m, s / np.sqrt(n) if n > 0 else 0.0
    elif error_type == "sd":
        return m, s
    else:  # ci95
        if n <= 1:
            return m, float("nan")
        ci = sp_stats.t.ppf(0.975, df=n - 1) * s / np.sqrt(n)
        return m, float(ci)


def _calc_error_asymmetric(vals, error_type):
    """Return (mean, err_down, err_up) with asymmetric bounds for log-scale plots.

    On a log axis, symmetric error bars in data units look wrong because the
    lower bar can cross zero or go negative.  This computes the error in log
    space and maps it back: the lower bar = mean - 10^(log10(mean) - e_log) and
    the upper bar = 10^(log10(mean) + e_log) - mean, ensuring both bars stay
    positive and the lower bar never exceeds the mean (which would
    extend through zero on a log axis).  Falls back to symmetric if mean <= 0."""
    m, half = _calc_error(vals, error_type)
    if m <= 0:
        return m, half, half
    try:
        log_m   = np.log10(m)
        log_err = np.log10(m + half) - log_m          # upper log offset
        lo_raw = m - 10 ** (log_m - log_err)          # lower asymmetric bar
        hi     = 10 ** (log_m + log_err) - m          # upper asymmetric bar
        # Clamp: lower bar must be < m — never extend through zero on log scale
        lo = float(np.clip(lo_raw, 0.0, m * 0.9999))
        return m, lo, max(float(hi), 0.0)
    except Exception:
        return m, half, half


# ---------------------------------------------------------------------------
# P-value helpers
# ---------------------------------------------------------------------------

def _p_to_stars(p: float, threshold: float = None) -> str:
    """Convert a p-value to Prism-style asterisk annotation.

    Uses the module-level __p_sig_threshold__ from chart_helpers so the app
    can raise or lower the significance cutoff (e.g. 0.01 to show only **
    and above).  Pairs with p > threshold are returned as 'ns' and will be
    hidden unless __show_ns__ is True.

    threshold: if provided, overrides __p_sig_threshold__ (thread-safe caller path).
    """
    # Import the module-level threshold lazily to avoid circular imports
    if threshold is None:
        try:
            from refraction.core import chart_helpers as _ch
            _threshold = _ch.__p_sig_threshold__
        except (ImportError, AttributeError):
            _threshold = 0.05
    else:
        _threshold = threshold
    if p > _threshold: return "ns"
    if p <= 0.0001:  return "****"
    elif p <= 0.001: return "***"
    elif p <= 0.01:  return "**"
    else:            return "*"


def _apply_correction(raw_p_list, method):
    """Apply multiple comparison correction to a list of raw p-values.
    Returns corrected p-values in the same order."""
    m = len(raw_p_list)
    if m == 0:
        return []
    p = np.array(raw_p_list, dtype=float)

    if method == "Bonferroni":
        return list(np.minimum(p * m, 1.0))

    elif method == "Holm-Bonferroni":
        order       = np.argsort(p)
        corrected   = np.empty(m)
        running_max = 0.0
        for rank_i, orig_i in enumerate(order):
            cp = min(p[orig_i] * (m - rank_i), 1.0)
            running_max = max(running_max, cp)
            corrected[orig_i] = running_max
        return list(corrected)

    elif method == "Benjamini-Hochberg (FDR)":
        order     = np.argsort(p)
        corrected = np.empty(m)
        running_min = 1.0
        for rank_i in range(m - 1, -1, -1):
            orig_i = order[rank_i]
            cp = min(p[orig_i] * m / (rank_i + 1), 1.0)
            running_min = min(running_min, cp)
            corrected[orig_i] = running_min
        return list(corrected)

    else:  # None / uncorrected
        return list(p)


# ---------------------------------------------------------------------------
# Statistical tests
# ---------------------------------------------------------------------------

def _run_stats(
    groups: dict,
    test_type: str = "parametric",
    n_permutations: int = 9999,
    control=None,
    mc_correction: str = "Holm-Bonferroni",
    posthoc: str = "Tukey HSD",
    mu0: float = 0.0,
) -> list:
    """
    Run statistical tests and return (group_a, group_b, p_value, stars) tuples.

    test_type ``"one_sample"`` compares each group's mean to *mu0* using a
    one-sample t-test.  Returns (group_name, f"μ₀={mu0}", p, stars) tuples.
    """
    labels  = list(groups.keys())
    results = []
    k       = len(labels)

    # ── One-sample t-test ─────────────────────────────────────────────────────
    if test_type == "one_sample":
        raw_p = []
        for g in labels:
            _, p = sp_stats.ttest_1samp(groups[g], popmean=mu0)
            raw_p.append(p)
        corrected = _apply_correction(raw_p, mc_correction)
        for g, cp in zip(labels, corrected):
            results.append((g, f"μ₀={mu0:g}", cp, _p_to_stars(cp)))
        return results

    # Need at least 2 groups for any pairwise comparison
    if k < 2:
        return []

    # ── Parametric ────────────────────────────────────────────────────────────
    if test_type == "paired":
        # Paired t-test: groups must have same length
        if k == 2:
            a, b = labels
            n = min(len(groups[a]), len(groups[b]))
            if len(groups[a]) != len(groups[b]):
                warnings.warn(
                    f"Paired test: '{a}' (n={len(groups[a])}) and '{b}' "
                    f"(n={len(groups[b])}) have unequal lengths; "
                    f"truncating to {n} pairs.",
                    stacklevel=2,
                )
            _, p = sp_stats.ttest_rel(groups[a][:n], groups[b][:n])
            corrected = _apply_correction([p], mc_correction)[0]
            results.append((a, b, corrected, _p_to_stars(corrected)))
        else:
            # Mauchly sphericity check for repeated measures (k >= 3)
            # Build difference-score matrix and test sphericity
            try:
                min_n = min(len(groups[g]) for g in labels)
                if min_n >= k:
                    data_matrix = np.column_stack([groups[g][:min_n] for g in labels])
                    # Compute k-1 orthogonal difference contrasts
                    C = np.zeros((k, k - 1))
                    for j in range(k - 1):
                        C[j, j] = 1.0
                        C[j + 1, j] = -1.0
                    D = data_matrix @ C  # n × (k-1)
                    S = np.cov(D, rowvar=False)
                    p_dim = S.shape[0]
                    if p_dim >= 2:
                        det_S = np.linalg.det(S)
                        trace_S = np.trace(S)
                        # Mauchly's W = det(S) / (trace(S)/p)^p
                        W = det_S / ((trace_S / p_dim) ** p_dim) if trace_S > 0 else 0
                        # Approximate chi-square test
                        df_w = p_dim * (p_dim + 1) // 2 - 1
                        n_subj = min_n
                        chi2_w = -(n_subj - 1 - (2 * p_dim + 1 + 2.0 / p_dim) / 6.0) * np.log(max(W, 1e-300))
                        p_mauchly = float(sp_stats.chi2.sf(chi2_w, df_w))
                        if p_mauchly < 0.05:
                            warnings.warn(
                                f"Mauchly's sphericity test significant "
                                f"(W={W:.4f}, p={p_mauchly:.4f}): "
                                "sphericity assumption may be violated. "
                                "Consider Greenhouse-Geisser corrected p-values.",
                                stacklevel=2,
                            )
            except Exception:
                pass  # Sphericity check is advisory; don't block analysis

            # Repeated-measures style: pairwise paired t-tests
            pairs = list(itertools.combinations(labels, 2))
            raw_p = []
            for a, b in pairs:
                n = min(len(groups[a]), len(groups[b]))
                if len(groups[a]) != len(groups[b]):
                    warnings.warn(
                        f"Paired test: '{a}' (n={len(groups[a])}) and '{b}' "
                        f"(n={len(groups[b])}) have unequal lengths; "
                        f"truncating to {n} pairs.",
                        stacklevel=2,
                    )
                _, p = sp_stats.ttest_rel(groups[a][:n], groups[b][:n])
                raw_p.append(p)
            corrected = _apply_correction(raw_p, mc_correction)
            for i, (a, b) in enumerate(pairs):
                results.append((a, b, corrected[i], _p_to_stars(corrected[i])))

    elif test_type == "parametric":
        # Levene test for homogeneity of variances (k >= 3, like Prism)
        if k >= 3:
            _, p_levene = sp_stats.levene(*[groups[g] for g in labels])
            if p_levene < 0.05:
                warnings.warn(
                    f"Levene's test significant (p={p_levene:.4f}): "
                    "group variances may be unequal. Consider Welch ANOVA "
                    "or a nonparametric test.",
                    stacklevel=2,
                )

        if k == 2:
            a, b = labels
            # Welch's t-test (equal_var=False) — Prism default since v8.
            # Does not assume equal variances; more robust for real-world data.
            _, p = sp_stats.ttest_ind(groups[a], groups[b], equal_var=False)
            corrected = _apply_correction([p], mc_correction)[0]
            results.append((a, b, corrected, _p_to_stars(corrected)))

        elif posthoc == "Dunnett (vs control)":
            # Dunnett's test: each treatment vs a single control reference.
            # scipy.stats.dunnett already controls the family-wise error rate
            # internally — applying an additional MC correction would be
            # double-penalising (overly conservative).  Prism uses Dunnett
            # p-values directly without a second correction step.
            ctrl = control if control is not None else labels[0]
            treatments       = [g for g in labels if g != ctrl]
            treatment_arrays = [groups[g] for g in treatments]
            from scipy.stats import dunnett as _dunnett
            res = _dunnett(*treatment_arrays, control=groups[ctrl])
            for i, trt in enumerate(treatments):
                p = float(res.pvalue[i])
                results.append((ctrl, trt, p, _p_to_stars(p)))

        elif posthoc == "Tukey HSD":
            all_vals  = np.concatenate(list(groups.values()))
            ss_within = sum(np.sum((v - v.mean()) ** 2) for v in groups.values())
            df_within = len(all_vals) - k
            ms_within = ss_within / df_within
            all_pairs = list(itertools.combinations(labels, 2))
            # Filter to control-vs-others only if a control is set
            pairs = [p for p in all_pairs
                     if control is None or p[0] == control or p[1] == control]
            raw_p = []
            for a, b in pairs:
                mean_diff = abs(groups[a].mean() - groups[b].mean())
                se        = np.sqrt((ms_within / 2) * (1/len(groups[a]) + 1/len(groups[b])))
                if se == 0 or np.isnan(se):
                    # Zero-variance groups: can't compute q — report p=1.0 (ns)
                    raw_p.append(1.0)
                else:
                    q         = mean_diff / se
                    raw_p.append(1 - sp_stats.studentized_range.cdf(q, k, df_within))
            corrected = (_apply_correction(raw_p, mc_correction)
                         if mc_correction not in ("Holm-Bonferroni", "None (uncorrected)")
                         else raw_p)
            for i, (a, b) in enumerate(pairs):
                results.append((a, b, corrected[i], _p_to_stars(corrected[i])))

        elif posthoc in ("Bonferroni", "Sidak", "Fisher LSD"):
            all_pairs = list(itertools.combinations(labels, 2))
            pairs = [p for p in all_pairs
                     if control is None or p[0] == control or p[1] == control]
            raw_p = []
            for a, b in pairs:
                # Welch's t-test for pairwise comparisons (Prism default)
                _, p = sp_stats.ttest_ind(groups[a], groups[b], equal_var=False)
                raw_p.append(p)
            if posthoc == "Sidak":
                m = len(raw_p)
                corrected = [min(1.0 - (1.0 - p) ** m, 1.0) for p in raw_p]
            elif posthoc == "Fisher LSD":
                corrected = raw_p
            else:
                corrected = _apply_correction(raw_p, mc_correction)
            for i, (a, b) in enumerate(pairs):
                results.append((a, b, corrected[i], _p_to_stars(corrected[i])))

    # ── Nonparametric ─────────────────────────────────────────────────────────
    elif test_type == "nonparametric":
        if k == 2:
            a, b = labels
            _, p = sp_stats.mannwhitneyu(groups[a], groups[b], alternative="two-sided")
            corrected = _apply_correction([p], mc_correction)[0]
            results.append((a, b, corrected, _p_to_stars(corrected)))
        else:
            _, p_kw = sp_stats.kruskal(*[groups[g] for g in labels])
            all_vals    = np.concatenate(list(groups.values()))
            ranks       = sp_stats.rankdata(all_vals)
            group_ranks = {}
            idx = 0
            for g in labels:
                n = len(groups[g])
                group_ranks[g] = ranks[idx:idx + n]
                idx += n
            _, counts = np.unique(all_vals, return_counts=True)
            tc        = 1 - np.sum(counts**3 - counts) / (len(all_vals)**3 - len(all_vals))
            all_pairs = list(itertools.combinations(labels, 2))
            pairs     = [p for p in all_pairs
                         if control is None or p[0] == control or p[1] == control]
            raw_p = []
            for a, b in pairs:
                se = np.sqrt(tc * len(all_vals) * (len(all_vals) + 1) / 12
                             * (1/len(groups[a]) + 1/len(groups[b])))
                z  = abs(group_ranks[a].mean() - group_ranks[b].mean()) / se
                raw_p.append(2 * (1 - sp_stats.norm.cdf(z)))
            corrected = _apply_correction(raw_p, mc_correction)
            for i, (a, b) in enumerate(pairs):
                results.append((a, b, corrected[i], _p_to_stars(corrected[i])))

    # ── Permutation ───────────────────────────────────────────────────────────
    elif test_type == "permutation":
        def _diff_of_means(x, y):
            return np.mean(x) - np.mean(y)
        all_pairs = list(itertools.combinations(labels, 2))
        pairs     = [p for p in all_pairs
                     if control is None or p[0] == control or p[1] == control]
        raw_p = []
        for a, b in pairs:
            res = sp_stats.permutation_test(
                (groups[a], groups[b]), _diff_of_means,
                permutation_type="samples", n_resamples=n_permutations,
                alternative="two-sided")
            raw_p.append(res.pvalue)
        corrected = _apply_correction(raw_p, mc_correction)
        for i, (a, b) in enumerate(pairs):
            results.append((a, b, corrected[i], _p_to_stars(corrected[i])))

    return results


# ---------------------------------------------------------------------------
# Effect sizes
# ---------------------------------------------------------------------------

def _cohens_d(a: np.ndarray, b: np.ndarray) -> float:
    """Cohen's d for two independent groups (pooled SD).

    Cohen (1988) Statistical Power Analysis for the Behavioral Sciences, 2nd ed.
    """
    n1, n2 = len(a), len(b)
    if n1 < 2 or n2 < 2:
        return float("nan")
    pooled_sd = np.sqrt(((n1 - 1) * np.var(a, ddof=1) +
                          (n2 - 1) * np.var(b, ddof=1)) / (n1 + n2 - 2))
    if pooled_sd == 0:
        return float("nan")
    return float((np.mean(a) - np.mean(b)) / pooled_sd)


def _hedges_g(a: np.ndarray, b: np.ndarray) -> float:
    """Hedges' g: small-sample bias-corrected Cohen's d.

    Multiplies Cohen's d by the correction factor J(m) ≈ 1 − 3/(4m − 1),
    where m = n1 + n2 − 2 (degrees of freedom).

    Reference: Hedges (1981) Biometrics 37:149–164.
    Hedges' g is the standard effect size for
    independent-samples comparisons.
    """
    d = _cohens_d(a, b)
    if np.isnan(d):
        return float("nan")
    m = len(a) + len(b) - 2
    if m <= 0:
        return float("nan")
    j = 1.0 - 3.0 / (4.0 * m - 1.0)   # correction factor
    return float(d * j)


def _rank_biserial_r(a: np.ndarray, b: np.ndarray) -> float:
    """Rank-biserial correlation r for Mann-Whitney U.

    r = (U₁ − U₂) / (n₁ × n₂), ranging from −1 to +1.
    Equivalent to r = 1 − 2·U_min/(n₁·n₂) with appropriate sign.
    Positive r means group a tends to have larger values.

    Reference: Cureton (1956) Psychometrika 21:287–290.
    This is the standard effect size for nonparametric
    two-group comparisons.
    """
    n1, n2 = len(a), len(b)
    if n1 < 1 or n2 < 1:
        return float("nan")
    # U1 = number of (a_i, b_j) pairs where a_i > b_j
    # mannwhitneyu returns U for the first sample with alternative="greater"
    # but for "two-sided" it returns the minimum. Use the definition directly:
    U1 = float(np.sum(a[:, None] > b[None, :]))   # vectorised count
    U2 = n1 * n2 - U1
    return float((U1 - U2) / (n1 * n2))


def _effect_label(d: float) -> str:
    """Rough verbal label for Cohen's d / Hedges' g magnitude.

    Cutoffs from Cohen (1988): <0.2 negligible, 0.2–0.5 small,
    0.5–0.8 medium, ≥0.8 large.
    """
    ad = abs(d)
    if ad < 0.2:  return "negligible"
    if ad < 0.5:  return "small"
    if ad < 0.8:  return "medium"
    return "large"


# ---------------------------------------------------------------------------
# Normality testing
# ---------------------------------------------------------------------------

def check_normality(groups: dict, alpha: float = 0.05) -> dict:
    """
    Run Shapiro-Wilk normality test on each group.
    Returns {group_name: (stat, p, is_normal, warning_msg)}
    """
    results = {}
    for name, vals in groups.items():
        vals = vals[~np.isnan(vals)] if hasattr(vals, '__len__') else vals
        n = len(vals)
        if n < 3:
            results[name] = (None, None, None,
                             f"'{name}': too few values (n={n}) for normality test")
            continue
        stat, p = sp_stats.shapiro(vals)
        is_normal = p > alpha
        if not is_normal:
            results[name] = (stat, p, False,
                             f"'{name}': non-normal (Shapiro-Wilk p={p:.4f})")
        else:
            results[name] = (stat, p, True, None)
    return results


# ---------------------------------------------------------------------------
# Survival analysis (Kaplan-Meier)
# ---------------------------------------------------------------------------

def _km_curve(times, events):
    """
    Compute Kaplan-Meier survival curve.
    Returns (unique_times, survival, lower_ci, upper_ci, n_at_risk, n_events)
    using Greenwood's formula for 95% CI (log-log transform).
    """
    times  = np.asarray(times,  dtype=float)
    events = np.asarray(events, dtype=float)
    order  = np.argsort(times)
    times, events = times[order], events[order]

    unique_times = np.unique(times[events == 1])
    n            = len(times)
    S            = 1.0
    survival     = [1.0]
    lower_ci     = [1.0]
    upper_ci     = [1.0]
    n_at_risk_   = [n]
    n_events_    = [0]
    greenwood    = 0.0
    t_out        = [0.0]

    n_remaining = n
    for t in unique_times:
        d_i = np.sum((times == t) & (events == 1))
        n_i = np.sum(times >= t)
        if n_i == 0: continue
        S          = S * (1.0 - d_i / n_i)
        if d_i < n_i:
            greenwood += d_i / (n_i * (n_i - d_i))
        # Greenwood log-log CI
        if S > 0 and S < 1:
            log_log_S   = np.log(-np.log(S))
            se_log_log  = np.sqrt(greenwood) / abs(np.log(S))
            z           = 1.96
            ll          = np.exp(-np.exp(log_log_S + z * se_log_log))
            ul          = np.exp(-np.exp(log_log_S - z * se_log_log))
        else:
            ll = ul = S

        t_out.append(t)
        survival.append(S)
        lower_ci.append(max(0.0, ll))
        upper_ci.append(min(1.0, ul))
        n_at_risk_.append(int(np.sum(times >= t)))
        n_events_.append(int(d_i))

    return (np.array(t_out), np.array(survival),
            np.array(lower_ci), np.array(upper_ci),
            np.array(n_at_risk_), np.array(n_events_))


def _logrank_test(groups_dict):
    """
    Pairwise log-rank tests between all groups.
    Returns list of (group_a, group_b, p_value, stars).
    """
    from itertools import combinations
    results = []
    keys = list(groups_dict.keys())
    for a, b in combinations(keys, 2):
        t1, e1 = groups_dict[a]
        t2, e2 = groups_dict[b]
        # Mantel-Cox log-rank
        all_times = np.unique(np.concatenate([t1[e1==1], t2[e2==1]]))
        O1 = O2 = E1 = E2 = 0.0
        var = 0.0
        for t in all_times:
            n1 = np.sum(t1 >= t); n2 = np.sum(t2 >= t)
            d1 = np.sum((t1 == t) & (e1 == 1))
            d2 = np.sum((t2 == t) & (e2 == 1))
            n  = n1 + n2; d = d1 + d2
            if n < 2: continue
            e1_exp = d * n1 / n
            O1 += d1; O2 += d2
            E1 += e1_exp; E2 += d - e1_exp
            var += (d * n1 * n2 * (n - d)) / (n**2 * (n - 1)) if n > 1 else 0
        if var > 0:
            chi2 = (O1 - E1)**2 / var
            p    = float(sp_stats.chi2.sf(chi2, df=1))
        else:
            p = 1.0
        results.append((a, b, p, _p_to_stars(p)))
    return results


# ---------------------------------------------------------------------------
# Two-way ANOVA
# ---------------------------------------------------------------------------

def _twoway_anova(df, dv, factor_a, factor_b):
    """
    Compute two-way ANOVA (Type III SS) from a long-format DataFrame.
    Returns dict with keys: factor_a, factor_b, interaction, residual.
    Each value: {SS, df, MS, F, p, eta2, eta2_partial}.
    Works for balanced and unbalanced designs.

    Type III SS (partial): each effect is tested after removing it from the
    full model that still includes all other effects (including the
    interaction term).  This matches the default in SPSS and SAS PROC GLM.

    eta2        = SS_effect / SS_total      (classical η²)
    eta2_partial = SS_effect / (SS_effect + SS_error)  (partial ηp²,
                   reported by Prism and most modern software)
    """
    import pandas as pd
    from itertools import product as iproduct

    y      = df[dv].values.astype(float)
    a_vals = df[factor_a].values
    b_vals = df[factor_b].values
    N      = len(y)

    a_levels = sorted(set(a_vals))
    b_levels = sorted(set(b_vals))
    I, J     = len(a_levels), len(b_levels)

    a_idx = {v: i for i, v in enumerate(a_levels)}
    b_idx = {v: i for i, v in enumerate(b_levels)}

    # ── Build design matrix (intercept + A dummies + B dummies + AB dummies) ──
    def _make_X(include_a, include_b, include_ab):
        cols = [np.ones(N)]
        if include_a:
            for i in range(I - 1):
                cols.append((a_vals == a_levels[i]).astype(float))
        if include_b:
            for j in range(J - 1):
                cols.append((b_vals == b_levels[j]).astype(float))
        if include_ab:
            for i, j in iproduct(range(I - 1), range(J - 1)):
                cols.append(((a_vals == a_levels[i]) &
                              (b_vals == b_levels[j])).astype(float))
        return np.column_stack(cols)

    def _rss(X):
        """Residual sum of squares from OLS projection."""
        beta, _, _, _ = np.linalg.lstsq(X, y, rcond=None)
        resid = y - X @ beta
        return float(np.dot(resid, resid))

    # Type III SS: each effect tested after removing it from the *full* model
    # (which includes all other main effects AND the interaction).
    rss_full   = _rss(_make_X(True,  True,  True))
    rss_no_a   = _rss(_make_X(False, True,  True))
    rss_no_b   = _rss(_make_X(True,  False, True))
    rss_no_ab  = _rss(_make_X(True,  True,  False))
    ss_total   = float(np.sum((y - y.mean()) ** 2))

    SS_A   = rss_no_a  - rss_full
    SS_B   = rss_no_b  - rss_full
    SS_AB  = rss_no_ab - rss_full
    SS_err = rss_full

    df_A   = I - 1
    df_B   = J - 1
    df_AB  = (I - 1) * (J - 1)
    df_err = N - I * J

    if df_err <= 0:
        raise ValueError("Not enough observations for two-way ANOVA "
                         f"({N} obs, {I*J} cells). Need >1 replicate per cell.")

    MS_A   = SS_A   / df_A
    MS_B   = SS_B   / df_B
    MS_AB  = SS_AB  / df_AB
    MS_err = SS_err / df_err

    def _F_p(MS_effect, df_effect):
        if MS_err <= 0 or MS_effect < 0: return float("nan"), 1.0
        F = MS_effect / MS_err
        p = float(sp_stats.f.sf(F, df_effect, df_err))
        return F, p

    F_A,  p_A  = _F_p(MS_A,  df_A)
    F_B,  p_B  = _F_p(MS_B,  df_B)
    F_AB, p_AB = _F_p(MS_AB, df_AB)

    return {
        factor_a:     {"SS": SS_A,  "df": df_A,  "MS": MS_A,  "F": F_A,  "p": p_A,
                        "eta2": SS_A  / ss_total,
                        "eta2_partial": SS_A  / (SS_A  + SS_err)},
        factor_b:     {"SS": SS_B,  "df": df_B,  "MS": MS_B,  "F": F_B,  "p": p_B,
                        "eta2": SS_B  / ss_total,
                        "eta2_partial": SS_B  / (SS_B  + SS_err)},
        "interaction": {"SS": SS_AB, "df": df_AB, "MS": MS_AB, "F": F_AB, "p": p_AB,
                        "eta2": SS_AB / ss_total,
                        "eta2_partial": SS_AB / (SS_AB + SS_err)},
        "residual":    {"SS": SS_err, "df": df_err, "MS": MS_err},
    }


def _twoway_posthoc(df, dv, factor_a, factor_b, correction="holm"):
    """
    Pairwise t-tests for each level of factor_A within each level of factor_B.
    Returns list of (label, group1, group2, p_raw, p_corr, stars).
    """
    from itertools import combinations

    results = []
    b_levels = sorted(df[factor_b].unique())
    a_levels = sorted(df[factor_a].unique())

    raw_ps = []
    pairs  = []

    for b_val in b_levels:
        sub = df[df[factor_b] == b_val]
        for a1, a2 in combinations(a_levels, 2):
            g1 = sub[sub[factor_a] == a1][dv].dropna().values
            g2 = sub[sub[factor_a] == a2][dv].dropna().values
            if len(g1) >= 2 and len(g2) >= 2:
                # Welch's t-test (equal_var=False) — consistent with Prism default
                # and with all other parametric post-hoc tests in this codebase.
                _, p = sp_stats.ttest_ind(g1, g2, equal_var=False)
                raw_ps.append(p)
                pairs.append((b_val, a1, a2))

    if not raw_ps:
        return []

    corr_ps = _apply_correction(raw_ps, "Holm-Bonferroni"
                                if correction == "holm" else correction)

    for (b_val, a1, a2), p_raw, p_corr in zip(pairs, raw_ps, corr_ps):
        results.append({
            "factor_b_level": b_val,
            "group1": a1, "group2": a2,
            "p_raw": p_raw, "p_corr": p_corr,
            "stars": _p_to_stars(p_corr),
        })

    return results


# ---------------------------------------------------------------------------
# Curve fitting
# ---------------------------------------------------------------------------

def _p0_range(x, y):
    """Utility: return (x_min, x_max, y_min, y_max, y_range, x_mid)."""
    xmn, xmx = float(np.nanmin(x)), float(np.nanmax(x))
    ymn, ymx = float(np.nanmin(y)), float(np.nanmax(y))
    return xmn, xmx, ymn, ymx, ymx - ymn, (xmn + xmx) / 2


def _make_4pl():
    """Return the 4-parameter logistic (Hill equation) model specification."""
    def fn(x, Bottom, Top, EC50, HillSlope):
        return Bottom + (Top - Bottom) / (1.0 + (EC50 / np.where(x == 0, 1e-12, x)) ** HillSlope)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymn, ymx, xm, 1.0]
    return fn, ["Bottom", "Top", "EC50", "HillSlope"], p0


def _make_3pl():
    """Return the 3-parameter logistic model specification."""
    def fn(x, Top, EC50, HillSlope):
        return Top / (1.0 + (EC50 / np.where(x == 0, 1e-12, x)) ** HillSlope)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx, xm, 1.0]
    return fn, ["Top", "EC50", "HillSlope"], p0


def _make_exp_decay1():
    """Return the single-component exponential decay model specification."""
    def fn(x, Y0, Plateau, K):
        return Plateau + (Y0 - Plateau) * np.exp(-K * x)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx, ymn, 1.0 / max(xm, 1e-9)]
    return fn, ["Y0", "Plateau", "K"], p0


def _make_exp_growth1():
    """Return the single-component exponential growth model specification."""
    def fn(x, Y0, Plateau, K):
        return Plateau - (Plateau - Y0) * np.exp(-K * x)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymn, ymx, 1.0 / max(xm, 1e-9)]
    return fn, ["Y0", "Plateau", "K"], p0


def _make_exp_decay2():
    """Return the two-component exponential decay model specification."""
    def fn(x, Y0, Plateau, K_fast, K_slow, Fraction_fast):
        frac = max(0.0, min(1.0, Fraction_fast))
        return (Plateau
                + (Y0 - Plateau) * frac       * np.exp(-K_fast * x)
                + (Y0 - Plateau) * (1 - frac) * np.exp(-K_slow * x))
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        k = 1.0 / max(xm, 1e-9)
        return [ymx, ymn, k * 3, k * 0.3, 0.5]
    return fn, ["Y0", "Plateau", "K_fast", "K_slow", "Fraction_fast"], p0


def _make_linear():
    """Return the linear (straight-line) model specification."""
    def fn(x, Slope, Intercept):
        return Slope * x + Intercept
    def p0(x, y):
        try:
            from scipy import stats as _st
            s, i, *_ = _st.linregress(x, y)
            return [s, i]
        except Exception:
            return [1.0, 0.0]
    return fn, ["Slope", "Intercept"], p0


def _make_poly2():
    """Return the second-degree polynomial model specification."""
    def fn(x, A, B, C):
        return A * x**2 + B * x + C
    def p0(x, y):
        return [0.0, 1.0, float(np.nanmean(y))]
    return fn, ["A (x²)", "B (x)", "C (const)"], p0


def _make_michaelis_menten():
    """Return the Michaelis-Menten enzyme kinetics model specification."""
    def fn(x, Vmax, Km):
        return Vmax * x / (Km + np.where(x == 0, 1e-12, x))
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx * 1.2, xm]
    return fn, ["Vmax", "Km"], p0


def _make_gaussian():
    """Return the Gaussian (normal distribution) model specification."""
    def fn(x, Amplitude, Mean, SD):
        return Amplitude * np.exp(-0.5 * ((x - Mean) / np.where(SD == 0, 1e-9, SD)) ** 2)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx, xm, (xmx - xmn) / 4]
    return fn, ["Amplitude", "Mean", "SD"], p0


def _make_hill():
    """Return the Hill sigmoidal dose-response model specification."""
    def fn(x, Vmax, K_half, n):
        xn = np.power(np.where(x <= 0, 1e-12, x), n)
        return Vmax * xn / (K_half**n + xn)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx, xm, 1.0]
    return fn, ["Vmax", "K_half", "n (Hill)"], p0


def _make_log_normal():
    """Return the log-normal cumulative distribution model specification."""
    def fn(x, Amplitude, mu, sigma):
        lx = np.log(np.where(x <= 0, 1e-12, x))
        return Amplitude * np.exp(-0.5 * ((lx - mu) / np.where(sigma == 0, 1e-9, sigma))**2)
    def p0(x, y):
        xmn, xmx, ymn, ymx, yr, xm = _p0_range(x, y)
        return [ymx, float(np.log(max(xm, 1e-9))), 1.0]
    return fn, ["Amplitude", "mu (log)", "sigma (log)"], p0


# Build the public model registry
CURVE_MODELS: dict = {}
for _name, _maker in [
    ("4PL Sigmoidal (EC50/IC50)",         _make_4pl),
    ("3PL Sigmoidal (no bottom)",          _make_3pl),
    ("One-phase exponential decay",        _make_exp_decay1),
    ("One-phase exponential growth",       _make_exp_growth1),
    ("Two-phase exponential decay",        _make_exp_decay2),
    ("Michaelis-Menten",                   _make_michaelis_menten),
    ("Hill equation",                      _make_hill),
    ("Gaussian (bell curve)",              _make_gaussian),
    ("Log-normal",                         _make_log_normal),
    ("Linear",                             _make_linear),
    ("Polynomial (2nd order)",             _make_poly2),
]:
    _fn, _params, _p0 = _maker()
    CURVE_MODELS[_name] = {"fn": _fn, "params": _params, "p0": _p0}


def _fit_model(x, y, model_name):
    """
    Fit a model to (x, y) data.
    Returns dict with keys: popt, pcov, perr, r2, residuals, model_name, param_names.
    Raises ValueError on failure.
    """
    from scipy.optimize import curve_fit

    model   = CURVE_MODELS[model_name]
    fn      = model["fn"]
    p_names = model["params"]
    p0_fn   = model["p0"]

    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    mask = np.isfinite(x) & np.isfinite(y)
    x, y = x[mask], y[mask]

    if len(x) < len(p_names) + 1:
        raise ValueError(f"Need at least {len(p_names)+1} points for {model_name} "
                         f"({len(x)} provided)")

    p0 = p0_fn(x, y)

    try:
        popt, pcov = curve_fit(fn, x, y, p0=p0, maxfev=10000,
                               full_output=False, check_finite=True)
    except Exception:
        # Try with tighter bounds / different initial guess
        popt, pcov = curve_fit(fn, x, y, p0=p0, maxfev=50000)

    perr     = np.sqrt(np.diag(pcov))
    y_pred   = fn(x, *popt)
    ss_res   = np.sum((y - y_pred) ** 2)
    ss_tot   = np.sum((y - np.mean(y)) ** 2)
    r2       = 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")
    residuals = y - y_pred

    return {
        "popt": popt, "pcov": pcov, "perr": perr,
        "r2": r2, "residuals": residuals,
        "model_name": model_name, "param_names": p_names,
        "x": x, "y": y,
    }


def _curve_ci_band(x_line, x_data, y_data, popt, fn, alpha=0.05):
    """Return (lower_ci, upper_ci) for the fitted curve using delta method."""
    from scipy import stats as _st
    from scipy.optimize import curve_fit

    n  = len(x_data)
    p  = len(popt)
    df = max(n - p, 1)
    t  = _st.t.ppf(1 - alpha / 2, df)

    # Numerical Jacobian of the model at each x in x_line
    eps   = 1e-6 * (np.abs(popt) + 1e-8)
    y0    = fn(x_line, *popt)
    J     = np.zeros((len(x_line), p))
    for i in range(p):
        dp = np.zeros(p); dp[i] = eps[i]
        J[:, i] = (fn(x_line, *(popt + dp)) - y0) / eps[i]

    try:
        _, pcov = curve_fit(fn, x_data, y_data, p0=popt, maxfev=100)
    except Exception:
        pcov = np.eye(p) * 1e-6

    se_line = np.sqrt(np.einsum("ij,jk,ik->i", J, pcov, J))
    return y0 - t * se_line, y0 + t * se_line


# ---------------------------------------------------------------------------
# Recommended statistical test
# ---------------------------------------------------------------------------

def recommend_test(
    groups: dict[str, np.ndarray],
    paired: bool = False,
    alpha: float = 0.05,
) -> dict:
    """Recommend the most appropriate statistical test based on data properties.

    Runs Shapiro-Wilk (normality) and Levene's (equal variance) tests on the
    groups, then selects the optimal test using standard decision criteria.

    Parameters
    ----------
    groups : dict[str, ndarray]
        Group name -> array of values.
    paired : bool
        Whether the observations are paired/repeated measures.
    alpha : float
        Significance level for normality/variance tests.

    Returns
    -------
    dict with keys:
        test : str — recommended test key (e.g. "welch_t", "mann_whitney")
        test_label : str — human-readable name
        posthoc : str | None — recommended posthoc method (for 3+ groups)
        justification : str — plain-English explanation of why this test
        checks : dict — results of diagnostic tests:
            normality : dict[str, {stat, p, normal}]
            all_normal : bool
            equal_variance : bool (Levene's p > alpha)
            levene_p : float | None
            n_groups : int
            paired : bool
            min_n : int
    """
    n_groups = len(groups)
    arrays = list(groups.values())
    min_n = min(len(a) for a in arrays) if arrays else 0

    # --- Normality check per group ---
    normality = {}
    all_normal = True
    for name, vals in groups.items():
        if len(vals) < 3:
            # Too few for Shapiro-Wilk; assume non-normal
            normality[name] = {"stat": None, "p": None, "normal": False}
            all_normal = False
        else:
            stat, p = sp_stats.shapiro(vals)
            is_normal = p > alpha
            normality[name] = {"stat": float(stat), "p": float(p), "normal": is_normal}
            if not is_normal:
                all_normal = False

    # --- Equal variance check (Levene's test, 2+ groups) ---
    equal_var = True
    levene_p = None
    if n_groups >= 2 and all(len(a) >= 2 for a in arrays):
        try:
            lev_stat, lev_p = sp_stats.levene(*arrays)
            levene_p = float(lev_p)
            equal_var = lev_p > alpha
        except Exception:
            equal_var = True  # fallback if Levene fails

    # --- Decision tree ---
    checks = {
        "normality": normality,
        "all_normal": all_normal,
        "equal_variance": equal_var,
        "levene_p": levene_p,
        "n_groups": n_groups,
        "paired": paired,
        "min_n": min_n,
    }

    if n_groups < 2:
        return {
            "test": "descriptive",
            "test_label": "Descriptive statistics only",
            "posthoc": None,
            "justification": "Only one group — no comparison test is applicable. "
                             "Descriptive statistics (mean, SD, SEM) are reported.",
            "checks": checks,
        }

    if n_groups == 2:
        if paired:
            if all_normal:
                return {
                    "test": "paired_t",
                    "test_label": "Paired t-test",
                    "posthoc": None,
                    "justification": (
                        "Two paired groups with normally distributed differences. "
                        "The paired t-test compares the mean difference against zero "
                        "and is the most powerful test for this design."
                    ),
                    "checks": checks,
                }
            else:
                return {
                    "test": "wilcoxon",
                    "test_label": "Wilcoxon signed-rank test",
                    "posthoc": None,
                    "justification": (
                        "Two paired groups but differences are not normally distributed "
                        f"(Shapiro-Wilk p < {alpha}). The Wilcoxon signed-rank test is "
                        "the nonparametric alternative to the paired t-test."
                    ),
                    "checks": checks,
                }
        else:
            if all_normal and equal_var:
                return {
                    "test": "unpaired_t",
                    "test_label": "Unpaired t-test",
                    "posthoc": None,
                    "justification": (
                        "Two independent groups, both normally distributed "
                        f"(Shapiro-Wilk p > {alpha}) with equal variances "
                        f"(Levene's p = {levene_p:.4f}). "
                        "The unpaired Student's t-test is optimal."
                    ),
                    "checks": checks,
                }
            elif all_normal and not equal_var:
                return {
                    "test": "welch_t",
                    "test_label": "Welch's t-test",
                    "posthoc": None,
                    "justification": (
                        "Two independent groups, both normally distributed, but "
                        f"unequal variances (Levene's p = {levene_p:.4f}). "
                        "Welch's t-test does not assume equal variances and is "
                        "recommended over Student's t-test here."
                    ),
                    "checks": checks,
                }
            else:
                return {
                    "test": "mann_whitney",
                    "test_label": "Mann-Whitney U test",
                    "posthoc": None,
                    "justification": (
                        "Two independent groups but at least one is not normally "
                        f"distributed (Shapiro-Wilk p < {alpha}). The Mann-Whitney U "
                        "test is the nonparametric alternative to the t-test and "
                        "compares the rank distributions."
                    ),
                    "checks": checks,
                }

    # n_groups >= 3
    if paired:
        if all_normal:
            return {
                "test": "rm_anova",
                "test_label": "Repeated measures one-way ANOVA",
                "posthoc": "Tukey HSD",
                "justification": (
                    f"{n_groups} paired groups, all normally distributed. "
                    "Repeated measures ANOVA tests for differences across "
                    "conditions while accounting for within-subject correlation. "
                    "Tukey HSD is recommended for pairwise posthoc comparisons."
                ),
                "checks": checks,
            }
        else:
            return {
                "test": "friedman",
                "test_label": "Friedman test",
                "posthoc": "Dunn",
                "justification": (
                    f"{n_groups} paired groups but at least one is not normally "
                    f"distributed (Shapiro-Wilk p < {alpha}). The Friedman test "
                    "is the nonparametric alternative to repeated measures ANOVA. "
                    "Dunn's test with Bonferroni correction is recommended for "
                    "pairwise posthoc comparisons."
                ),
                "checks": checks,
            }
    else:
        if all_normal and equal_var:
            return {
                "test": "anova",
                "test_label": "Ordinary one-way ANOVA",
                "posthoc": "Tukey HSD",
                "justification": (
                    f"{n_groups} independent groups, all normally distributed "
                    f"(Shapiro-Wilk p > {alpha}) with equal variances "
                    f"(Levene's p = {levene_p:.4f}). Ordinary one-way ANOVA is "
                    "the standard parametric test. Tukey HSD provides exact "
                    "family-wise error control for all pairwise comparisons."
                ),
                "checks": checks,
            }
        elif all_normal and not equal_var:
            return {
                "test": "welch_anova",
                "test_label": "Welch's ANOVA",
                "posthoc": "Games-Howell",
                "justification": (
                    f"{n_groups} independent groups, all normally distributed, but "
                    f"unequal variances (Levene's p = {levene_p:.4f}). "
                    "Welch's ANOVA does not assume homogeneity of variance. "
                    "Games-Howell posthoc test is recommended as it also handles "
                    "unequal variances."
                ),
                "checks": checks,
            }
        else:
            return {
                "test": "kruskal_wallis",
                "test_label": "Kruskal-Wallis test",
                "posthoc": "Dunn",
                "justification": (
                    f"{n_groups} independent groups but at least one is not normally "
                    f"distributed (Shapiro-Wilk p < {alpha}). The Kruskal-Wallis test "
                    "is the nonparametric alternative to one-way ANOVA and compares "
                    "rank distributions. Dunn's test is recommended for pairwise "
                    "posthoc comparisons."
                ),
                "checks": checks,
            }
