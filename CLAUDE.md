# Refraction -- Project Context for Claude Code

GraphPad Prism-style scientific plotting application for macOS.
Built entirely by Claude (Anthropic) with Ashwin Pasupathy.

---

## The one rule before every commit

```bash
python3 run_all.py   # must print 0 failures
```

Never commit if core tests fail. Never skip it. If tests regress, fix them
before doing anything else.

---

## Commands

```bash
# Run the full test suite (4 suites, ~30 seconds)
python3 run_all.py

# Run a single suite
python3 run_all.py stats              #  56 tests -- statistical verification + control logic
python3 run_all.py validators         #  35 tests -- spreadsheet validators
python3 run_all.py specs              #  11+ tests -- Plotly spec builders + server (needs plotly)
python3 run_all.py api                #  18 tests -- FastAPI endpoint tests

# Launch the app
python3 plotter_desktop.py            # Desktop entry point (pywebview + FastAPI)
python3 plotter_web_server.py         # Standalone web server (no Tk)

# One-command setup (installs Python deps + npm build)
./setup.sh

# Build macOS .app bundle (PyInstaller + optional DMG)
./build_app.sh

# Quick syntax check
python3 -c "import refraction; print('OK')"
```

---

## Developer documentation

Detailed docs live in `docs/`:

- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** -- rendering pipeline, dependency
  graph, key App methods, helper function tables, style constants, Excel layout
  conventions, chart type reference
- **[docs/ADDING_CHARTS.md](docs/ADDING_CHARTS.md)** -- the 5-step checklist for
  adding a new chart type
- **[docs/TESTING.md](docs/TESTING.md)** -- test harness patterns, fixtures, test
  suite reference, CI notes

---

## File map

```
# -- Core application (refraction package) -------------------------
refraction/                           Python package root
refraction/core/config.py             Canonical source for all style constants & palettes
refraction/core/chart_helpers.py      Stats helpers, color utilities, style kwargs
refraction/core/validators.py         Spreadsheet validators
refraction/core/registry.py           PlotTypeConfig registry (29 entries)
refraction/core/tabs.py               Multi-tab state (TabState, TabManager, TabBar)
refraction/core/presets.py            Style preset load/save (.json)
refraction/core/session.py            Session persistence
refraction/core/events.py             EventBus for pub/sub messaging
refraction/core/types.py              Shared type definitions and dataclasses
refraction/core/undo.py               UndoStack for undo/redo
refraction/core/errors.py             ErrorReporter: structured error handling
refraction/core/comparisons.py        Custom comparison builder

# -- Plotly spec builders ------------------------------------------
refraction/specs/theme.py             Plotly theme (PRISM_TEMPLATE) -- imports from config
refraction/specs/helpers.py           Shared spec builder utilities
refraction/specs/bar.py               Bar chart spec builder
refraction/specs/grouped_bar.py       Grouped bar spec builder
refraction/specs/line.py              Line graph spec builder
refraction/specs/scatter.py           Scatter plot spec builder
refraction/specs/box.py               Box plot spec builder
refraction/specs/violin.py            Violin plot spec builder
refraction/specs/histogram.py         Histogram spec builder
refraction/specs/dot_plot.py          Dot plot spec builder
refraction/specs/raincloud.py         Raincloud spec builder
refraction/specs/qq.py                Q-Q plot spec builder
refraction/specs/ecdf.py              ECDF spec builder
refraction/specs/before_after.py      Before/After spec builder
refraction/specs/repeated_measures.py Repeated measures spec builder
refraction/specs/subcolumn.py         Subcolumn scatter spec builder
refraction/specs/stacked_bar.py       Stacked bar spec builder
refraction/specs/area.py              Area chart spec builder
refraction/specs/lollipop.py          Lollipop spec builder
refraction/specs/waterfall.py         Waterfall spec builder
refraction/specs/pyramid.py           Pyramid spec builder
refraction/specs/kaplan_meier.py      Kaplan-Meier spec builder
refraction/specs/heatmap.py           Heatmap spec builder
refraction/specs/bland_altman.py      Bland-Altman spec builder
refraction/specs/forest_plot.py       Forest plot spec builder
refraction/specs/bubble.py            Bubble chart spec builder
refraction/specs/curve_fit.py         Curve fit spec builder
refraction/specs/column_stats.py      Column statistics spec builder
refraction/specs/contingency.py       Contingency spec builder
refraction/specs/chi_square_gof.py    Chi-Square GoF spec builder
refraction/specs/two_way_anova.py     Two-Way ANOVA spec builder

# -- Server & deployment -------------------------------------------
refraction/server/                    FastAPI server package
plotter_desktop.py                    Desktop entry point (pywebview + FastAPI)
plotter_web_server.py                 Standalone web server entry point
plotter_web/                          React SPA (Vite + TypeScript + Plotly.js)
Dockerfile                            Docker deployment config
setup.sh                              One-command setup script
build_app.sh                          PyInstaller + optional DMG builder

# -- Tests ---------------------------------------------------------
tests/plotter_test_harness.py         Shared test bootstrap
run_all.py                            4-suite unified test runner
tests/test_stats.py                   Statistical verification (57 tests)
tests/test_validators.py              Spreadsheet validator tests (35 tests)
tests/test_api.py                     FastAPI endpoint tests (18 tests)
tests/test_phase3_plotly.py           Plotly spec builders + server (11+ tests)
tests/test_png_render.py              All 29 chart PNG render tests (29 tests)
tests/visual_test.py                  Visual regression tests (manual)

# -- Docs & config -------------------------------------------------
docs/ARCHITECTURE.md                  Rendering pipeline, helpers, style constants
docs/ADDING_CHARTS.md                 How to add a new chart type
docs/TESTING.md                       Test harness patterns and fixtures
docs/archive/                         Phase 2-4 development notes
.github/workflows/ci.yml             CI: tests + lint on push/PR
```

---

## Commit conventions

```
feat: add lollipop chart and wire into sidebar
fix: correct y-axis drag clamping for zero-mean data
test: add 8 ECDF validator tests
refactor: extract prism_export.py from barplot_app
docs: update CLAUDE.md with pyramid chart layout
```

Always run `python3 run_all.py` and confirm 0 failures before pushing.

---

## Known gotchas

1. **`_ensure_imports()` must be first** in every chart function. matplotlib is
   `None` at module load time. Calling `plt.subplots()` before `_ensure_imports()`
   raises `TypeError: 'NoneType' is not callable`.

2. **`_style_kwargs(locals())`** must be called *after all parameters are defined*
   but *before* any code that modifies locals(). Call it immediately after
   `_base_plot_setup()`.

3. **Docstring indentation after multi-line signatures** -- if you add a docstring
   to a function with multi-line parameters, place the docstring *after the closing
   `):`, never between parameter lines.

4. **Canvas-mode and `_canvas_widget`** -- in canvas mode `self._canvas_widget`
   is `None`. Check for `None` before calling `.get_tk_widget()`.

5. **`_bar_renderer` lifetime** -- cleared to `None` before each new render.
   Check for `None` before using.

6. **`ttk.Treeview` heading colours on macOS Aqua theme** -- `ttk.Style.configure`
   heading background is ignored on Aqua. Requires `style.theme_use("clam")`.

7. **`_populate_results` for grouped charts** -- `df.select_dtypes(include="number")`
   merges two-row-header layout incorrectly. Known issue.

8. **`_kw_snap` deep-copy** -- taken *after* `spec.filter_kwargs` strips keys.
   `build_bar_scene` reads `kw["excel_path"]` so the path must survive the filter.

9. **Headless / CI environments** -- Tk modules need a display. Run
   `xvfb-run python3 run_all.py` on CI if Tk tests are included.

10. **All new modules use `refraction/` package structure** -- never create
    flat `plotter_` prefix modules at the root. Use `refraction/core/`,
    `refraction/specs/`, `refraction/server/`, etc.

11. **`plotter_registry.py` is the canonical source** for `PlotTypeConfig` entries.
    Do not add new chart types directly to `plotter_barplot_app.py`.

12. **`.cplot` files are ZIP archives** -- they contain `settings.json` +
    the original Excel file. Do not assume plain JSON.

13. **Plotly is optional** -- the `plotly` package is required only for spec
    builders. Desktop matplotlib rendering works without it.

14. **Spec builders read Excel directly** -- they do NOT go through
    `plotter_functions.py`. Visual parity uses `PRISM_PALETTE` and
    `PRISM_TEMPLATE` from `refraction/core/config.py`.

15. **`plotter_server.py` vs `plotter_web_server.py`** -- `plotter_server.py`
    defines the FastAPI app. `plotter_web_server.py` is a thin entry point.

16. **React SPA build** -- Run `cd plotter_web && npm install && npm run build`
    before deployment. The dist/ directory must exist for static file serving.

17. **PRISM_PALETTE is defined once** in `refraction/core/config.py` and
    re-exported by `refraction/core/chart_helpers.py` and
    `refraction/specs/theme.py`. Do not duplicate it.
