# Claude Prism — LLM Handoff Document

**Generated:** 2026-03-17 (Session 13)
**Archive:** `claude_prism_v11.zip` → folder `prism_v10/`
**Test status:** 571 / 571 passing across 5 suites

---

## Quick Start

```bash
# Verify everything is green before touching anything
python3 run_all.py   # must print 571/571 with 0 failures
```

If any test fails, fix it before proceeding. The test count must stay at 571 or higher after any change.

---

## Session 13 Changes

### Modular refactor — three new companion modules

The main app was split into focused, independently testable modules. The three new files have no dependencies on each other or on `prism_barplot_app.py`.

---

#### `prism_widgets.py` — 952 lines

All design-system tokens, custom Tk widget classes, and shared UI helpers, extracted from the top of `prism_barplot_app.py`.

| Exported symbol | Description |
|---|---|
| `_DS` | Design-system colour / font constants — edit once, propagates everywhere |
| `PButton` | Styled push button with `primary` / `secondary` / `ghost` variants |
| `PCheckbox` | Canvas-rendered checkbox with crisp check mark at any DPI |
| `PRadioGroup` | Row of canvas-dot radio buttons sharing a `StringVar` |
| `PEntry` | Flat-border entry widget with 1 px focus ring |
| `PCombobox` | Styled combobox wrapping `ttk.Combobox` |
| `section_sep` | Blue-tinted section-header band for grid layouts |
| `_create_tooltip` | Plain hover tooltip attachable to any widget |
| `add_placeholder` | Grey hint text shown when entry is empty and unfocused |
| `_bind_scroll_recursive` | Safe subtree scroll binding (alternative to `bind_all`) |
| `LABELS`, `HINTS` | Field metadata dicts; access via `label(key)` / `hint(key)` / `tip(widget, key)` |
| `_is_num`, `_non_numeric_values`, `_scipy_summary`, `_sys_bg` | Utility functions |

**Headless-safe:** `tkinter` import is guarded by `_TK_AVAILABLE`. When tkinter is absent a no-op stub base class (`_TkFrameStub`) stands in, so the module imports cleanly in CI / headless test environments. Tests that only check class-level attributes work without a display; tests that instantiate widgets need one.

---

#### `prism_validators.py` — 483 lines

All 11 spreadsheet validation functions extracted as standalone pure functions. Each accepts a `pandas.DataFrame` and returns `(errors: list[str], warnings: list[str])`.

| Function | Validates |
|---|---|
| `validate_flat_header(df, min_groups, min_rows, chart_name)` | Shared base for all flat-header charts |
| `validate_bar(df)` | Bar, Box, Violin, Subcolumn, Before/After, Repeated Measures |
| `validate_line(df)` | Line, Scatter, Curve Fit |
| `validate_grouped_bar(df)` | Grouped Bar, Stacked Bar |
| `validate_kaplan_meier(df)` | Kaplan-Meier survival |
| `validate_heatmap(df)` | Heatmap |
| `validate_two_way_anova(df)` | Two-Way ANOVA (long format) |
| `validate_contingency(df)` | Contingency table |
| `validate_chi_square_gof(df)` | Chi-square goodness of fit |
| `validate_bland_altman(df)` | Bland-Altman method agreement |
| `validate_forest_plot(df)` | Forest plot (meta-analysis) |

**Dispatch:** `App._validate_spreadsheet` checks `_VALIDATORS_AVAILABLE` and calls the standalone function when possible, falling back to `getattr(self, spec.validate)(df)` for any chart type not yet extracted. The original `App._validate_*` methods are retained as fallbacks but are no longer the primary path.

---

#### `prism_results.py` — 387 lines

Results panel logic extracted as three standalone functions that accept the `app` object as their first argument (thin delegation from the original App methods).

| Function | Replaces |
|---|---|
| `populate_results(app, excel_path, sheet, plot_type, kw_snapshot)` | `App._populate_results` |
| `export_results_csv(app)` | `App._export_results_csv` |
| `copy_results_tsv(app)` | `App._copy_results_tsv` |

---

#### `prism_barplot_app.py` — import block

The file now starts with a module docstring describing the six-file architecture, followed by guarded imports from all three new companion modules:

```python
from prism_widgets    import _DS, PButton, ..., _is_num, _scipy_summary
from prism_validators import validate_bar, validate_line, ...
from prism_results    import populate_results, export_results_csv, copy_results_tsv
```

Each import is wrapped in `try/except ImportError` with a `print()` warning so the app still starts in degraded mode if a companion file is missing.

---

### Documentation pass

- **`prism_functions.py`** — added docstrings to all 11 `_make_*` curve-fit model factory functions that were previously undocumented.
- **`prism_canvas_renderer.py`** — added docstrings to all colour helpers (`_hex_to_rgb`, `_rgb_to_hex`, `_darken_hex`, `_rgba_to_hex`, `_blend_alpha`), utility functions (`_calc_error_plain`, `_read_bar_groups`, `_prism_palette_n`, `_fmt_tick_label`), and bare dataclasses (`BarElement`, `BarScene`, `ClickResult`, `CoordTransform`, `GroupedBarGroup`, `GroupedBarScene`).
- **`prism_widgets.py`** — every exported symbol has a full docstring at class and method level.
- **`prism_validators.py`** — every `validate_*` function has a one-line docstring describing its expected Excel layout.

---

### New test suite: `test_modular.py` — 53 tests

Added as the `"modular"` suite in `run_all.py`.

| Section | Tests |
|---|---|
| prism_widgets: module structure | 9 |
| prism_widgets: utility functions | 7 |
| prism_widgets: widget class attributes | 6 |
| prism_validators: flat-header | 6 |
| prism_validators: line chart | 2 |
| prism_validators: grouped bar | 3 |
| prism_validators: kaplan-meier | 2 |
| prism_validators: heatmap | 2 |
| prism_validators: miscellaneous | 6 |
| prism_results: module structure | 4 |
| prism_validators: module integrity | 3 |
| prism_widgets: module integrity | 3 |

---

## Architecture

### File map

```
prism_v10/
├── prism_barplot_app.py     7,834 lines   App class, PLOT_REGISTRY, icon helpers
├── prism_widgets.py           952 lines   _DS tokens, P-widgets, shared UI helpers
├── prism_validators.py        483 lines   Standalone spreadsheet validators
├── prism_results.py           387 lines   Results panel: populate / export / copy
├── prism_functions.py       5,711 lines   29 Matplotlib chart functions
├── prism_canvas_renderer.py 1,687 lines   tk.Canvas bar + grouped-bar renderer
├── prism_test_harness.py      363 lines   Shared test bootstrap (imported once)
├── run_all.py                 110 lines   5-suite unified test runner
├── test_comprehensive.py    1,341 lines   309 tests — all 29 chart types
├── test_p1_p2_p3.py           796 lines    80 tests — style params, regressions
├── test_control.py            437 lines    20 tests — control-group statistics
├── test_canvas_renderer.py  1,306 lines   109 tests — CanvasRenderer + Grouped
└── test_modular.py            562 lines    53 tests — widget / validator / results
```

### Dependency graph

```
prism_barplot_app.py
  ├── prism_widgets.py          (no prism deps — pure Tk + constants)
  ├── prism_validators.py       (no prism deps — pure pandas)
  ├── prism_results.py          (accepts app object; no other prism imports)
  ├── prism_functions.py        (numpy, pandas, matplotlib, scipy — lazy imports)
  └── prism_canvas_renderer.py  (numpy, pandas — no matplotlib)
```

### Rendering pipeline

```
User clicks "Generate Plot"
        │
        ▼
App._do_run(kw)  [background thread]
  calls prism_functions.prism_<chart_type>(**kw)
  deepcopy(kw) → _kw_snap
        │
        ▼
App._embed_plot(fig, groups, kw=_kw_snap)  [main thread, via after(0)]
  ┌─ canvas_mode AND plot_type in ("bar", "grouped_bar")? ──────────┐
  │  YES → App._try_canvas_embed(fig, kw)                           │
  │         builds BarScene / GroupedBarScene                        │
  │         CanvasRenderer / GroupedCanvasRenderer                   │
  │         live hit-test, recolour, Y-drag, bar-width drag          │
  └─ NO  → FigureCanvasTkAgg(fig)  (standard Agg path)  ───────────┘
```

### Key App methods

| Method | Purpose |
|---|---|
| `App._do_run(kw)` | Background thread: calls the plot function, schedules `_embed_plot` |
| `App._embed_plot(fig, groups, kw)` | Main thread: shows chart (canvas or Agg) |
| `App._try_canvas_embed(fig, kw)` | Builds the tk.Canvas renderer; returns True on success |
| `App._collect(excel)` → `kw` | Assembles the full kwargs dict from all UI variables |
| `App._collect_display(kw)` | Error bars, points, colours, alpha, axis style |
| `App._collect_labels(kw)` | Title, xlabel, ytitle |
| `App._collect_stats(kw)` | Stats test, posthoc, correction, permutations |
| `App._collect_figsize(kw)` | figsize, bar_width, font_size, jitter |
| `App._validate_spreadsheet()` | Reads the sheet, dispatches to validator, shows result |
| `App._populate_results(...)` | Delegated to `prism_results.populate_results(app, ...)` |
| `App._build_sidebar(left)` | Chart-type selector (icons + labels) |
| `App._tab_data(f, mode)` | Data tab: file picker, sheet, colour, labels |
| `App._tab_axes(f, mode)` | Axes tab: Y scale, limits, font, bar width |
| `App._tab_stats(f)` | Stats tab: test type, posthoc, correction |

---

## Test Counts

```
run_all.py  →  571 / 571 pass

  comprehensive    →  309 / 309
  p1p2p3           →   80 /  80
  control          →   20 /  20
  canvas_renderer  →  109 / 109
  modular          →   53 /  53   (new in session 13)
```

---

## Remaining Work

### High priority

| Issue | Detail |
|---|---|
| **Treeview heading colours on macOS Aqua** | `ttk.Style` heading background is ignored under the Aqua theme. Fix: call `style.theme_use("clam")` before building the results panel, or draw custom headings. |
| **Results panel for grouped charts** | `populate_results` calls `df.select_dtypes(include="number")` which misreads the two-row-header grouped layout. Fix: add a chart-type dispatch inside `populate_results()` that calls `_read_grouped_groups()` from `prism_canvas_renderer` for grouped and stacked charts. |
| **Canvas mode toggle for grouped bars** | `_toggle_canvas_mode` only re-triggers a run when `plot_type == "bar"`. Fix: change the condition to `plot_type in ("bar", "grouped_bar")`. |

### Medium priority

- Missing statistical tests: Cochran's Q, McNemar, mixed-effects RM-ANOVA
- `ytitle_right` field in the UI for twin-axis charts (P19)
- Keyboard navigation shortcuts: ⌘1 / ⌘2 / ⌘3 to switch tabs
- Box-plot canvas renderer (`BoxBarScene`)

### Quick wins

- Add a "Copy Table" button to each Treeview section in the results panel
- Permutation progress ticker: time one trial run to calibrate the percentage estimate
- `snapshot_png`: render offscreen at 2× for Retina-quality PNG export

### Charts implemented but not yet wired into the sidebar

These functions exist in `prism_functions.py` and are tested in `test_comprehensive.py` but do not appear in the app's chart selector. To expose them, follow Step 2 of the adding-a-chart checklist in `CLAUDE.md`.

| Function | UI label when wired |
|---|---|
| `prism_area_chart` | Area Chart |
| `prism_raincloud` | Raincloud |
| `prism_qq_plot` | Q-Q Plot |
| `prism_lollipop` | Lollipop |
| `prism_waterfall` | Waterfall |
| `prism_pyramid` | Pyramid |
| `prism_ecdf` | ECDF |

---

## Gotchas (Session 13 additions)

These extend the list maintained in `CLAUDE.md`.

### 48 — `_TK_AVAILABLE` guard in `prism_widgets`

When tkinter is absent the widget classes inherit from `_TkFrameStub` (a no-op stub). Attempting to *instantiate* them (e.g. `PButton(parent)`) will silently succeed but produce an unusable object. Tests that check class-level constants (`._is_pwidget`, `._BOX`) work correctly without a display; tests that actually create a widget need a real display.

### 49 — Docstring insertion via regex

The two passes that added docstrings to `prism_functions.py` and `prism_canvas_renderer.py` used regex substitution which mis-placed some docstrings inside multi-line function signatures. Both were corrected with a targeted de-indent pass.

If adding docstrings to either file in future, always place them *after* the closing `):`, never between parameter lines:

```python
# Correct
def fn(arg1,
       arg2):
    """Docstring goes here, after the closing parenthesis."""

# Wrong — regex passes have broken this before
def fn(arg1,
    """This placement corrupts the signature."""
       arg2):
```

### 50 — `prism_validators.py` is the canonical validator source

The original `App._validate_*` methods still exist in `prism_barplot_app.py` as fallbacks. The dispatch in `_validate_spreadsheet` prefers the standalone versions via `_STANDALONE_VALIDATORS`. Long term the App methods should be removed once all validators are confirmed identical to their standalone counterparts.
