"""
plotter_chart_helpers.py
------------------------
Shared constants, palettes, and presentation helper functions.
Statistical computation lives in refraction.core.stats.
"""

import numpy as np
import pandas as pd
from scipy import stats

# Module-level flags — set by the app before calling stats functions
__show_ns__                  = False
__show_normality_warning__   = True
__p_sig_threshold__          = 0.05

__all__ = [
    "AXIS_STYLES", "CURVE_MODELS", "LEGEND_POSITIONS", "MARKER_CYCLE",
    "PLOT_PARAM_DEFAULTS", "PRISM_PALETTE", "TICK_DIRS",
    "__show_ns__", "__show_normality_warning__", "__p_sig_threshold__",
    "_apply_correction", "_calc_error", "_calc_error_asymmetric",
    "_cohens_d", "_curve_ci_band", "_effect_label", "_fit_model",
    "_fmt_bar_label", "_get_font", "_hedges_g", "_km_curve",
    "_logrank_test", "_make_3pl", "_make_exp_decay1",
    "_make_exp_decay2", "_make_exp_growth1", "_make_gaussian",
    "_make_hill", "_make_linear", "_make_log_normal",
    "_make_michaelis_menten", "_make_poly2", "_n_labels", "_p0_range",
    "_p_to_stars", "_param", "_rank_biserial_r", "_run_stats",
    "_scale_errorbar_lw", "_smart_xrotation", "_style_kwargs",
    "_twoway_anova", "_twoway_posthoc",
    "check_normality", "normality_warning",
    "np", "pd", "stats",
]

# ---------------------------------------------------------------------------
# Import all constants from the canonical config module.
# Local aliases preserve backward compatibility for code that references
# the old module-level names (e.g. _DPI, _FONT, PRISM_PALETTE).
# ---------------------------------------------------------------------------

from refraction.core.config import (          # noqa: F401 — re-exports
    DEFAULT_CONFIG,
    PRISM_PALETTE,
    AXIS_STYLES,
    TICK_DIRS,
    LEGEND_POSITIONS,
    MARKER_CYCLE,
    PLOT_PARAM_DEFAULTS,
)

_cfg = DEFAULT_CONFIG

_DPI             = _cfg.dpi
_FONT            = _cfg.font
_LW_AXIS         = _cfg.lw_axis
_LW_ERR          = _cfg.lw_err
_LW_GRID         = _cfg.lw_grid
_LW_REF          = _cfg.lw_ref
_CAP_SIZE        = _cfg.cap_size
_LABEL_PAD       = _cfg.label_pad
_TITLE_PAD       = _cfg.title_pad
_TIGHT_PAD       = _cfg.tight_pad
_ALPHA_BAR       = _cfg.alpha_bar
_ALPHA_POINT     = _cfg.alpha_point
_ALPHA_CI        = _cfg.alpha_ci
_ALPHA_LINE      = _cfg.alpha_line
_PT_SIZE         = _cfg.pt_size
_PT_LW           = _cfg.pt_lw
_DARKEN          = _cfg.darken
_COLOR_ANNOT     = _cfg.color_annot
_COLOR_WARN      = _cfg.color_warn
_COLOR_SUBJ      = _cfg.color_subj
_COLOR_BOX       = _cfg.color_box
_COLOR_ANNO_SUBTLE = _cfg.color_anno_subtle
_COLOR_HDR       = _cfg.color_hdr
_COLOR_WARN_FILL = _cfg.color_warn_fill
_COLOR_BG        = _cfg.color_bg
_MEAN_TICK_HALF  = _cfg.mean_tick_half
_MEAN_TICK_LW    = _cfg.mean_tick_lw
_PAIR_ERR_LW     = _cfg.pair_err_lw
_PAIR_CAP_SIZE   = _cfg.pair_cap_size
_SUBJ_LINE_LW   = _cfg.subj_line_lw
_SUBJ_LINE_ALPHA = _cfg.subj_line_alpha


# ---------------------------------------------------------------------------
# Presentation helpers
# ---------------------------------------------------------------------------


def _fmt_bar_label(v: float) -> str:
    """Format a bar-top value label with 3 significant figures, no trailing zeros."""
    if v != v:          # NaN guard
        return ""
    if v == 0:
        return "0"
    abs_v = abs(v)
    if abs_v >= 1000 or abs_v < 0.001:
        return f"{v:.2e}"
    if abs_v >= 100:
        return f"{v:.0f}"
    if abs_v >= 10:
        return f"{v:.1f}"
    return f"{v:.2f}"


def _smart_xrotation(group_order):
    """Return (rotation, ha) for x-axis tick labels.
    Uses n_groups × max_label_length as a combined measure of crowding.
    Labels only stay horizontal when the product is small enough that
    there is no risk of overlap at typical figure widths.
    """
    max_len = max((len(str(g)) for g in group_order), default=0)
    crowding = len(group_order) * max_len
    if crowding > 12 or len(group_order) > 4:
        return 45, "right"
    return 0, "center"


def _scale_errorbar_lw(bar_width: float) -> float:
    """Return an error-bar linewidth that scales proportionally with bar width.
    At bar_width=0.6 (default) the line is 1.0 pt; scales linearly."""
    return max(0.5, round(bar_width / 0.6, 2))


def _n_labels(group_order, groups, font_size):
    """Return tick labels with n= appended: ['Control\nn=6', ...]"""
    return [f"{g}\nn={len(groups[g])}" for g in group_order]


def _style_kwargs(kw: dict) -> dict:
    """Extract the presentation style keys from a locals() / kwargs dict.

    Usage in any plot function::

        _sk = _style_kwargs(locals())
        _apply_plotter_style(ax, font_size, **_sk)
        # …
        _base_plot_finish(ax, fig, …, **_sk)

    Centralising the key list here means adding a new style param requires
    only one change (PLOT_PARAM_DEFAULTS above + the function signature)
    rather than editing every call site.

    The function deliberately returns only the three keys that
    ``_apply_plotter_style`` / ``_base_plot_finish`` accept, so it is safe to
    unpack with ** into those helpers without leaking unrelated keys.
    """
    return {
        "axis_style":     kw.get("axis_style",     PLOT_PARAM_DEFAULTS["axis_style"]),
        "tick_dir":       kw.get("tick_dir",       PLOT_PARAM_DEFAULTS["tick_dir"]),
        "minor_ticks":    kw.get("minor_ticks",    PLOT_PARAM_DEFAULTS["minor_ticks"]),
        "ytick_interval": kw.get("ytick_interval", PLOT_PARAM_DEFAULTS["ytick_interval"]),
        "xtick_interval": kw.get("xtick_interval", PLOT_PARAM_DEFAULTS["xtick_interval"]),
        "fig_bg":         kw.get("fig_bg",         PLOT_PARAM_DEFAULTS["fig_bg"]),
        "spine_width":    kw.get("spine_width",    PLOT_PARAM_DEFAULTS["spine_width"]),
    }


def _param(kw: dict, key: str):
    """Retrieve *key* from *kw* (typically locals()), falling back to
    PLOT_PARAM_DEFAULTS.  Useful in function bodies to avoid repetitive
    ``kw.get("x", some_literal)`` calls.

    Example::

        cap = _param(locals(), "cap_size")  # → float from arg or default
    """
    return kw.get(key, PLOT_PARAM_DEFAULTS.get(key))


def _get_font() -> str:
    """Return the plot font name (Arial)."""
    return _FONT


# ---------------------------------------------------------------------------
# Normality warning (presentation layer — uses check_normality from stats)
# ---------------------------------------------------------------------------

def normality_warning(groups: dict, test_type: str) -> str:
    """
    Return a warning string if normality is violated and a parametric test is selected.
    Returns empty string if no warning needed or if the flag is disabled.
    """
    _show_normality_warning = __show_normality_warning__  # thread-safe local snapshot
    if not _show_normality_warning:
        return ""
    if test_type != "parametric":
        return ""
    results = check_normality(groups)
    warnings_list = [v[3] for v in results.values() if v[3] is not None]
    if warnings_list:
        return ("Normality assumption may be violated:\n" +
                "\n".join(warnings_list) +
                "\nConsider using a non-parametric test.")
    return ""


# ---------------------------------------------------------------------------
# Backward-compatible re-exports (prefer importing from refraction.core.stats directly)
# ---------------------------------------------------------------------------

from refraction.core.stats import (  # noqa: E402, F401
    _calc_error, _calc_error_asymmetric, _run_stats, _apply_correction,
    _p_to_stars, _cohens_d, _hedges_g, _rank_biserial_r, _effect_label,
    check_normality, _km_curve, _logrank_test, _twoway_anova, _twoway_posthoc,
    _fit_model, _curve_ci_band, _p0_range,
    _make_4pl, _make_3pl, _make_exp_decay1, _make_exp_decay2,
    _make_exp_growth1, _make_gaussian, _make_hill, _make_linear,
    _make_log_normal, _make_michaelis_menten, _make_poly2,
    CURVE_MODELS,
)
