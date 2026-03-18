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


# ─────────────────────────────────────────────────────────────────────────────
# Final summary
# ─────────────────────────────────────────────────────────────────────────────

_h.summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
