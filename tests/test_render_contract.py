"""
test_render_contract.py
=======================
Contract tests for the /render pipeline: analyze() → _to_chart_spec() → ChartSpec JSON.

For each of the 29 chart types, verifies:
  - analyze() returns ok: True
  - _to_chart_spec() produces valid ChartSpec structure
  - groups have names, colors, and values (generic types)
  - data payload is present (dedicated analyzer types)
  - style.colors matches group count
  - brackets have valid indices when stats are enabled
"""

import os
import sys
import re

import numpy as np
import pytest

# ── Ensure project root is importable ──────────────────────────────────────
_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ROOT = os.path.dirname(_HERE)
if _PROJECT_ROOT not in sys.path:
    sys.path.insert(0, _PROJECT_ROOT)

from refraction.analysis.engine import analyze
from refraction.server.api import _to_chart_spec
from tests.conftest import (
    _bar_excel, _line_excel, _simple_xy_excel, _grouped_excel,
    _km_excel, _heatmap_excel, _two_way_excel, _contingency_excel,
    _chi_gof_excel, _bland_altman_excel, _forest_excel, _bubble_excel,
    _with_excel, THREE_GROUPS, PAIRED_GROUPS, SCATTER_XS, SCATTER_YS,
)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")


def _run_pipeline(chart_type: str, excel_path: str, config: dict | None = None):
    """Run analyze() + _to_chart_spec() and return (result, spec)."""
    config = config or {}
    result = analyze(chart_type, excel_path, config)
    assert result.get("ok") is True, f"analyze() failed for {chart_type}: {result.get('error')}"
    spec = _to_chart_spec(result, config)
    return result, spec


def _assert_valid_spec_structure(spec: dict, chart_type: str):
    """Assert the ChartSpec has all required top-level keys."""
    assert spec["chart_type"] == chart_type
    assert isinstance(spec["style"], dict)
    assert isinstance(spec["axes"], dict)
    assert "colors" in spec["style"]
    assert "error_type" in spec["style"]
    assert "title" in spec["axes"]


def _assert_valid_groups(spec: dict, min_groups: int = 1):
    """Assert groups are well-formed."""
    groups = spec["groups"]
    assert len(groups) >= min_groups, f"expected >= {min_groups} groups, got {len(groups)}"
    for i, g in enumerate(groups):
        assert g["name"], f"group {i} has empty name"
        assert HEX_RE.match(g["color"]), f"group {i} color is not valid hex: {g['color']}"
        vals = g["values"]
        assert isinstance(vals["raw"], list), f"group {i} raw values not a list"
        assert vals["n"] >= 0, f"group {i} has negative n"


def _assert_colors_match_groups(spec: dict):
    """Assert style.colors has same count as groups."""
    n_groups = len(spec["groups"])
    n_colors = len(spec["style"]["colors"])
    if n_groups > 0:
        assert n_colors == n_groups, f"colors ({n_colors}) != groups ({n_groups})"


def _assert_valid_brackets(spec: dict):
    """Assert brackets have valid group indices."""
    n_groups = len(spec["groups"])
    for b in spec.get("brackets", []):
        assert 0 <= b["left_index"] < n_groups, f"left_index {b['left_index']} out of range"
        assert 0 <= b["right_index"] < n_groups, f"right_index {b['right_index']} out of range"
        assert b["left_index"] < b["right_index"], "left_index >= right_index"
        assert isinstance(b["label"], str)
        assert isinstance(b["stacking_order"], int)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Generic chart types (use the common groups/comparisons path)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rng = np.random.default_rng(42)


class TestBarContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("bar", path)
            _assert_valid_spec_structure(spec, "bar")
            _assert_valid_groups(spec, min_groups=3)
            _assert_colors_match_groups(spec)
        finally:
            os.unlink(path)

    def test_with_stats(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("bar", path, {"stats_test": "parametric"})
            _assert_valid_spec_structure(spec, "bar")
            _assert_valid_groups(spec, min_groups=3)
            assert spec["stats"] is not None, "stats should be present"
            assert len(spec["brackets"]) > 0, "brackets should be present"
            _assert_valid_brackets(spec)
        finally:
            os.unlink(path)


class TestBoxContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("box", path)
            _assert_valid_spec_structure(spec, "box")
            _assert_valid_groups(spec, min_groups=3)
            _assert_colors_match_groups(spec)
            # Box plots need raw values for quartile computation
            for g in spec["groups"]:
                assert len(g["values"]["raw"]) > 0, "box plot needs raw values"
        finally:
            os.unlink(path)


class TestViolinContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("violin", path)
            _assert_valid_spec_structure(spec, "violin")
            _assert_valid_groups(spec, min_groups=3)
            _assert_colors_match_groups(spec)
        finally:
            os.unlink(path)


class TestHistogramContract:
    def test_basic(self):
        data = {"Values": _rng.normal(0, 1, 50)}
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline("histogram", path)
            _assert_valid_spec_structure(spec, "histogram")
            _assert_valid_groups(spec, min_groups=1)
        finally:
            os.unlink(path)


class TestScatterContract:
    def test_basic(self):
        path = _simple_xy_excel(SCATTER_XS, SCATTER_YS)
        try:
            _, spec = _run_pipeline("scatter", path)
            _assert_valid_spec_structure(spec, "scatter")
            # Dedicated XY analyzer: data payload with x_values + series
            assert spec.get("data"), "scatter must have data payload"
            assert "x_values" in spec["data"]
            assert "series" in spec["data"]
        finally:
            os.unlink(path)


class TestLineContract:
    def test_basic(self):
        path = _simple_xy_excel(SCATTER_XS, SCATTER_YS)
        try:
            _, spec = _run_pipeline("line", path)
            _assert_valid_spec_structure(spec, "line")
            assert spec.get("data"), "line must have data payload"
            assert "x_values" in spec["data"]
            assert "series" in spec["data"]
        finally:
            os.unlink(path)


class TestGroupedBarContract:
    def test_basic(self):
        data = {
            "Cat1": {"SubA": _rng.normal(5, 1, 5), "SubB": _rng.normal(7, 1, 5)},
            "Cat2": {"SubA": _rng.normal(6, 1, 5), "SubB": _rng.normal(9, 1, 5)},
        }
        path = _grouped_excel(["Cat1", "Cat2"], ["SubA", "SubB"], data)
        try:
            result, spec = _run_pipeline("grouped_bar", path)
            _assert_valid_spec_structure(spec, "grouped_bar")
            # Dedicated analyzer: data payload has categories/subgroups/means
            assert spec.get("data"), "grouped_bar must have data payload"
            assert "categories" in spec["data"]
            assert "subgroups" in spec["data"]
            assert "means" in spec["data"]
        finally:
            os.unlink(path)


class TestBeforeAfterContract:
    def test_basic(self):
        path = _bar_excel(PAIRED_GROUPS)
        try:
            _, spec = _run_pipeline("before_after", path)
            _assert_valid_spec_structure(spec, "before_after")
            _assert_valid_groups(spec, min_groups=2)
            _assert_colors_match_groups(spec)
        finally:
            os.unlink(path)


class TestAreaChartContract:
    def test_basic(self):
        path = _simple_xy_excel(SCATTER_XS, SCATTER_YS)
        try:
            _, spec = _run_pipeline("area_chart", path)
            _assert_valid_spec_structure(spec, "area_chart")
            assert spec.get("data"), "area_chart must have data payload"
            assert "series" in spec["data"]
        finally:
            os.unlink(path)


class TestECDFContract:
    def test_basic(self):
        data = {"Values": _rng.normal(0, 1, 30)}
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline("ecdf", path)
            _assert_valid_spec_structure(spec, "ecdf")
            _assert_valid_groups(spec, min_groups=1)
        finally:
            os.unlink(path)


class TestQQPlotContract:
    def test_basic(self):
        data = {"Values": _rng.normal(0, 1, 30)}
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline("qq_plot", path)
            _assert_valid_spec_structure(spec, "qq_plot")
            _assert_valid_groups(spec, min_groups=1)
        finally:
            os.unlink(path)


class TestLollipopContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("lollipop", path)
            _assert_valid_spec_structure(spec, "lollipop")
            _assert_valid_groups(spec, min_groups=3)
            _assert_colors_match_groups(spec)
        finally:
            os.unlink(path)


class TestWaterfallContract:
    def test_basic(self):
        data = {"Revenue": np.array([100.0]), "Costs": np.array([-40.0]),
                "Tax": np.array([-15.0]), "Profit": np.array([45.0])}
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline("waterfall", path)
            _assert_valid_spec_structure(spec, "waterfall")
            _assert_valid_groups(spec, min_groups=1)
        finally:
            os.unlink(path)


class TestPyramidContract:
    def test_basic(self):
        data = {"Male": _rng.normal(50, 10, 5), "Female": _rng.normal(52, 10, 5)}
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline("pyramid", path)
            _assert_valid_spec_structure(spec, "pyramid")
            _assert_valid_groups(spec, min_groups=2)
        finally:
            os.unlink(path)


class TestStackedBarContract:
    def test_basic(self):
        data = {
            "Cat1": {"SubA": _rng.normal(5, 1, 5), "SubB": _rng.normal(7, 1, 5)},
            "Cat2": {"SubA": _rng.normal(6, 1, 5), "SubB": _rng.normal(9, 1, 5)},
        }
        path = _grouped_excel(["Cat1", "Cat2"], ["SubA", "SubB"], data)
        try:
            result, spec = _run_pipeline("stacked_bar", path)
            _assert_valid_spec_structure(spec, "stacked_bar")
            # Dedicated analyzer (reuses grouped_bar): data payload
            assert spec.get("data"), "stacked_bar must have data payload"
        finally:
            os.unlink(path)


class TestHeatmapContract:
    def test_basic(self):
        matrix = _rng.normal(0, 1, (3, 4))
        path = _heatmap_excel(matrix, ["R1", "R2", "R3"], ["C1", "C2", "C3", "C4"])
        try:
            _, spec = _run_pipeline("heatmap", path)
            _assert_valid_spec_structure(spec, "heatmap")
            # Heatmap may not use standard groups
            _assert_valid_groups(spec, min_groups=1)
        finally:
            os.unlink(path)


class TestTwoWayAnovaContract:
    def test_basic(self):
        records = []
        for a in ["Low", "High"]:
            for b in ["Control", "Treatment"]:
                for val in _rng.normal(5 if a == "Low" else 8, 1, 5):
                    records.append((a, b, float(val)))
        path = _two_way_excel(records)
        try:
            result, spec = _run_pipeline("two_way_anova", path)
            _assert_valid_spec_structure(spec, "two_way_anova")
            # Dedicated analyzer: data payload has cell means and ANOVA table
            assert spec.get("data"), "two_way_anova must have data payload"
            assert "a_levels" in spec["data"]
            assert "b_levels" in spec["data"]
            assert "cell_means" in spec["data"]
            assert "anova_table" in spec["data"]
        finally:
            os.unlink(path)


class TestSubcolumnScatterContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("subcolumn_scatter", path)
            _assert_valid_spec_structure(spec, "subcolumn_scatter")
            _assert_valid_groups(spec, min_groups=3)
        finally:
            os.unlink(path)


class TestColumnStatsContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("column_stats", path)
            _assert_valid_spec_structure(spec, "column_stats")
            _assert_valid_groups(spec, min_groups=3)
        finally:
            os.unlink(path)


class TestRepeatedMeasuresContract:
    def test_basic(self):
        path = _bar_excel(PAIRED_GROUPS)
        try:
            _, spec = _run_pipeline("repeated_measures", path)
            _assert_valid_spec_structure(spec, "repeated_measures")
            _assert_valid_groups(spec, min_groups=2)
        finally:
            os.unlink(path)


class TestCurveFitContract:
    def test_basic(self):
        path = _simple_xy_excel(SCATTER_XS, SCATTER_YS)
        try:
            _, spec = _run_pipeline("curve_fit", path)
            _assert_valid_spec_structure(spec, "curve_fit")
            assert spec.get("data"), "curve_fit must have data payload"
            assert "series" in spec["data"]
        finally:
            os.unlink(path)


class TestBubbleContract:
    def test_basic(self):
        xs = np.linspace(1, 10, 8)
        ys = _rng.normal(5, 1, 8)
        sizes = _rng.uniform(10, 100, 8)
        path = _bubble_excel(xs, ys, sizes)
        try:
            _, spec = _run_pipeline("bubble", path)
            _assert_valid_spec_structure(spec, "bubble")
            assert spec.get("data"), "bubble must have data payload"
        finally:
            os.unlink(path)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Dedicated analyzer chart types (have 'data' payload)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class TestKaplanMeierContract:
    def test_basic(self):
        km_data = {
            "Control": {
                "time": np.array([1, 3, 5, 7, 9, 11, 13, 15]),
                "event": np.array([1, 0, 1, 1, 0, 1, 0, 1]),
            },
            "Treatment": {
                "time": np.array([2, 4, 6, 8, 10, 12, 14, 16]),
                "event": np.array([0, 1, 0, 0, 1, 0, 1, 1]),
            },
        }
        path = _km_excel(km_data)
        try:
            result, spec = _run_pipeline("kaplan_meier", path)
            _assert_valid_spec_structure(spec, "kaplan_meier")
            # Dedicated analyzer: must have data payload
            assert spec.get("data"), "kaplan_meier must have data payload"
        finally:
            os.unlink(path)


class TestForestPlotContract:
    def test_basic(self):
        path = _forest_excel(
            studies=["Study A", "Study B", "Study C"],
            effects=[0.5, 0.8, 0.3],
            ci_lo=[0.1, 0.4, -0.1],
            ci_hi=[0.9, 1.2, 0.7],
        )
        try:
            result, spec = _run_pipeline("forest_plot", path)
            _assert_valid_spec_structure(spec, "forest_plot")
            assert spec.get("data"), "forest_plot must have data payload"
        finally:
            os.unlink(path)


class TestBlandAltmanContract:
    def test_basic(self):
        method_a = _rng.normal(100, 10, 20)
        method_b = method_a + _rng.normal(2, 3, 20)
        path = _bland_altman_excel(method_a, method_b)
        try:
            result, spec = _run_pipeline("bland_altman", path)
            _assert_valid_spec_structure(spec, "bland_altman")
            assert spec.get("data"), "bland_altman must have data payload"
        finally:
            os.unlink(path)


class TestContingencyContract:
    def test_basic(self):
        matrix = np.array([[30, 10], [20, 40]])
        path = _contingency_excel(["Group A", "Group B"], ["Yes", "No"], matrix)
        try:
            result, spec = _run_pipeline("contingency", path)
            _assert_valid_spec_structure(spec, "contingency")
            assert spec.get("data"), "contingency must have data payload"
        finally:
            os.unlink(path)


class TestChiSquareGoFContract:
    def test_basic(self):
        path = _chi_gof_excel(
            categories=["A", "B", "C", "D"],
            observed=[25, 30, 20, 25],
        )
        try:
            result, spec = _run_pipeline("chi_square_gof", path)
            _assert_valid_spec_structure(spec, "chi_square_gof")
            assert spec.get("data"), "chi_square_gof must have data payload"
        finally:
            os.unlink(path)


class TestRaincloudContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            result, spec = _run_pipeline("raincloud", path)
            _assert_valid_spec_structure(spec, "raincloud")
            assert spec.get("data"), "raincloud must have data payload"
        finally:
            os.unlink(path)


class TestDotPlotContract:
    def test_basic(self):
        path = _bar_excel(THREE_GROUPS)
        try:
            result, spec = _run_pipeline("dot_plot", path)
            _assert_valid_spec_structure(spec, "dot_plot")
            assert spec.get("data"), "dot_plot must have data payload"
        finally:
            os.unlink(path)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Cross-cutting contract: stats + brackets
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class TestStatsAndBrackets:
    """Verify stats and brackets work for generic column types."""

    @pytest.mark.parametrize("chart_type", ["bar", "box", "violin", "before_after"])
    def test_parametric_brackets(self, chart_type):
        data = PAIRED_GROUPS if chart_type == "before_after" else THREE_GROUPS
        path = _bar_excel(data)
        try:
            _, spec = _run_pipeline(chart_type, path, {"stats_test": "parametric"})
            assert spec["stats"] is not None, f"no stats for {chart_type}"
            assert len(spec["brackets"]) > 0, f"no brackets for {chart_type}"
            _assert_valid_brackets(spec)
        finally:
            os.unlink(path)

    @pytest.mark.parametrize("chart_type", ["bar", "box", "violin"])
    def test_nonparametric_brackets(self, chart_type):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline(chart_type, path, {"stats_test": "nonparametric"})
            assert spec["stats"] is not None, f"no stats for {chart_type}"
            assert len(spec["brackets"]) > 0, f"no brackets for {chart_type}"
            _assert_valid_brackets(spec)
        finally:
            os.unlink(path)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Error type contract
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class TestErrorTypes:
    @pytest.mark.parametrize("error_type", ["sem", "sd", "ci95"])
    def test_error_type_propagates(self, error_type):
        path = _bar_excel(THREE_GROUPS)
        try:
            _, spec = _run_pipeline("bar", path, {"error_type": error_type})
            assert spec["style"]["error_type"] == error_type
            for g in spec["groups"]:
                vals = g["values"]
                assert vals.get(error_type) is not None, \
                    f"group missing {error_type} value"
        finally:
            os.unlink(path)
