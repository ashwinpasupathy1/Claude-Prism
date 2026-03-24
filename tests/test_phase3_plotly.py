"""Phase 3 — Plotly spec builder tests."""

import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import plotter_test_harness as _h
from plotter_test_harness import run, section, bar_excel, simple_xy_excel
import numpy as np

# ===================================================================
# Phase 3: Plotly spec builders
# ===================================================================

section("Phase 3: Plotly spec builders — bar")

def test_bar_spec_returns_json():
    xl = bar_excel({"Control": np.array([1,2,3]), "Drug": np.array([4,5,6])})
    try:
        from plotter_spec_bar import build_bar_spec
        spec_json = build_bar_spec({"excel_path": xl, "title": "Test"})
        spec = json.loads(spec_json)
        assert "data" in spec, "Missing 'data' key"
        assert "layout" in spec, "Missing 'layout' key"
    finally:
        os.unlink(xl)
run("plotter_spec_bar: returns valid Plotly JSON", test_bar_spec_returns_json)


def test_bar_spec_has_two_traces():
    xl = bar_excel({"Control": np.array([1,2,3]), "Drug": np.array([4,5,6])})
    try:
        from plotter_spec_bar import build_bar_spec
        spec = json.loads(build_bar_spec({"excel_path": xl}))
        assert len(spec["data"]) == 2, f"Expected 2 traces, got {len(spec['data'])}"
    finally:
        os.unlink(xl)
run("plotter_spec_bar: two groups = two traces", test_bar_spec_has_two_traces)


def test_bar_spec_means_correct():
    xl = bar_excel({"A": np.array([10, 20, 30])})
    try:
        from plotter_spec_bar import build_bar_spec
        spec = json.loads(build_bar_spec({"excel_path": xl}))
        assert abs(spec["data"][0]["y"][0] - 20.0) < 0.01
    finally:
        os.unlink(xl)
run("plotter_spec_bar: mean is correct", test_bar_spec_means_correct)


section("Phase 3: Plotly spec builders — line")

def test_line_spec_returns_json():
    xl = simple_xy_excel(np.array([1,2,3]), np.array([4,5,6]), "X", "Y1")
    try:
        from plotter_spec_line import build_line_spec
        spec = json.loads(build_line_spec({"excel_path": xl}))
        assert "data" in spec
    finally:
        os.unlink(xl)
run("plotter_spec_line: returns valid Plotly JSON", test_line_spec_returns_json)


def test_line_spec_mode():
    xl = simple_xy_excel(np.array([1,2,3]), np.array([4,5,6]))
    try:
        from plotter_spec_line import build_line_spec
        spec = json.loads(build_line_spec({"excel_path": xl}))
        assert spec["data"][0]["mode"] == "lines+markers"
    finally:
        os.unlink(xl)
run("plotter_spec_line: mode is lines+markers", test_line_spec_mode)


section("Phase 3: Plotly spec builders — scatter")

def test_scatter_spec_returns_json():
    xl = simple_xy_excel(np.array([1,2,3]), np.array([4,5,6]))
    try:
        from plotter_spec_scatter import build_scatter_spec
        spec = json.loads(build_scatter_spec({"excel_path": xl}))
        assert "data" in spec
    finally:
        os.unlink(xl)
run("plotter_spec_scatter: returns valid Plotly JSON", test_scatter_spec_returns_json)


def test_scatter_spec_mode_markers():
    xl = simple_xy_excel(np.array([1,2,3]), np.array([4,5,6]))
    try:
        from plotter_spec_scatter import build_scatter_spec
        spec = json.loads(build_scatter_spec({"excel_path": xl}))
        assert spec["data"][0]["mode"] == "markers"
    finally:
        os.unlink(xl)
run("plotter_spec_scatter: mode is markers", test_scatter_spec_mode_markers)


section("Phase 3: Plotly theme")

def test_theme_palette_length():
    from plotter_plotly_theme import PRISM_PALETTE
    assert len(PRISM_PALETTE) == 10
run("plotter_plotly_theme: palette has 10 colors", test_theme_palette_length)


def test_theme_template_structure():
    from plotter_plotly_theme import PRISM_TEMPLATE
    assert "layout" in PRISM_TEMPLATE
    assert "xaxis" in PRISM_TEMPLATE["layout"]
    assert "yaxis" in PRISM_TEMPLATE["layout"]
run("plotter_plotly_theme: template has expected structure", test_theme_template_structure)


section("Phase 3: FastAPI server")

def test_server_starts():
    from plotter_server import start_server, get_port
    import urllib.request
    start_server()
    time.sleep(2)
    try:
        resp = urllib.request.urlopen(f"http://127.0.0.1:{get_port()}/health", timeout=3)
        assert resp.status == 200
    except Exception as e:
        assert False, f"Server did not start: {e}"
run("plotter_server: /health endpoint responds", test_server_starts)


def test_server_render_endpoint():
    from plotter_server import get_port
    import urllib.request
    xl = bar_excel({"A": np.array([1,2,3]), "B": np.array([4,5,6])})
    try:
        payload = json.dumps({"chart_type": "bar", "kw": {"excel_path": xl}}).encode()
        req = urllib.request.Request(
            f"http://127.0.0.1:{get_port()}/render",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        resp = urllib.request.urlopen(req, timeout=5)
        data = json.loads(resp.read())
        assert data["ok"] is True, f"Render failed: {data}"
        assert "spec" in data
    finally:
        os.unlink(xl)
run("plotter_server: /render returns Plotly spec", test_server_render_endpoint)


# ===================================================================
# SEM accuracy test — verifies sample variance (n-1), not population (n)
# ===================================================================

section("Phase 3: SEM calculation accuracy")

def test_bar_spec_sem_matches_scipy():
    """SEM in bar spec should match scipy.stats.sem (which uses ddof=1)."""
    from scipy import stats as scipy_stats
    vals_a = np.array([2.0, 4.0, 6.0, 8.0, 10.0])
    vals_b = np.array([1.0, 3.0, 5.0, 7.0, 9.0])
    expected_sem_a = scipy_stats.sem(vals_a)  # uses ddof=1 by default
    expected_sem_b = scipy_stats.sem(vals_b)

    xl = bar_excel({"A": vals_a, "B": vals_b})
    try:
        from plotter_spec_bar import build_bar_spec
        spec = json.loads(build_bar_spec({"excel_path": xl}))
        actual_sem_a = spec["data"][0]["error_y"]["array"][0]
        actual_sem_b = spec["data"][1]["error_y"]["array"][0]
        assert abs(actual_sem_a - expected_sem_a) < 1e-10, \
            f"SEM mismatch: got {actual_sem_a}, expected {expected_sem_a}"
        assert abs(actual_sem_b - expected_sem_b) < 1e-10, \
            f"SEM mismatch: got {actual_sem_b}, expected {expected_sem_b}"
    finally:
        os.unlink(xl)
run("plotter_spec_bar: SEM matches scipy.stats.sem (sample variance)", test_bar_spec_sem_matches_scipy)


# ===================================================================
# NaN handling in scatter/line — should not crash or misalign arrays
# ===================================================================

section("Phase 3: NaN handling in scatter/line")

def test_scatter_with_nan():
    """Scatter spec should handle NaN values without crashing."""
    import pandas as pd, tempfile
    df = pd.DataFrame({"X": [1, 2, 3, 4, 5], "Y": [10, np.nan, 30, np.nan, 50]})
    tmp = tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False)
    df.to_excel(tmp.name, index=False)
    tmp.close()
    try:
        from plotter_spec_scatter import build_scatter_spec
        spec_json = build_scatter_spec({"excel_path": tmp.name})
        spec = json.loads(spec_json)
        assert "data" in spec, "Missing data key"
        # X and Y arrays should be the same length (NaN rows dropped)
        x_len = len(spec["data"][0]["x"])
        y_len = len(spec["data"][0]["y"])
        assert x_len == y_len, f"Array mismatch: x={x_len}, y={y_len}"
        assert x_len == 3, f"Expected 3 non-NaN pairs, got {x_len}"
    finally:
        os.unlink(tmp.name)
run("plotter_spec_scatter: NaN rows dropped, arrays aligned", test_scatter_with_nan)

def test_line_with_nan():
    """Line spec should handle NaN values without crashing."""
    import pandas as pd, tempfile
    df = pd.DataFrame({"X": [1, 2, 3, 4], "Y1": [10, np.nan, 30, 40]})
    tmp = tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False)
    df.to_excel(tmp.name, index=False)
    tmp.close()
    try:
        from plotter_spec_line import build_line_spec
        spec_json = build_line_spec({"excel_path": tmp.name})
        spec = json.loads(spec_json)
        x_len = len(spec["data"][0]["x"])
        y_len = len(spec["data"][0]["y"])
        assert x_len == y_len, f"Array mismatch: x={x_len}, y={y_len}"
        assert x_len == 3, f"Expected 3 non-NaN pairs, got {x_len}"
    finally:
        os.unlink(tmp.name)
run("plotter_spec_line: NaN rows dropped, arrays aligned", test_line_with_nan)


# ===================================================================
# Open-spine styling — verify template includes mirror: false
# ===================================================================

section("Phase 3: Open-spine styling in template")

def test_template_has_open_spine():
    """PRISM_TEMPLATE should have mirror=False for open-spine styling."""
    from plotter_plotly_theme import PRISM_TEMPLATE
    xaxis = PRISM_TEMPLATE["layout"]["xaxis"]
    yaxis = PRISM_TEMPLATE["layout"]["yaxis"]
    assert xaxis.get("mirror") is False, "xaxis should have mirror=False"
    assert yaxis.get("mirror") is False, "yaxis should have mirror=False"
run("plotter_plotly_theme: template has open-spine (mirror=False)", test_template_has_open_spine)


# ─────────────────────────────────────────────────────────────────────────────
# Final summary
# ─────────────────────────────────────────────────────────────────────────────

_h.summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
