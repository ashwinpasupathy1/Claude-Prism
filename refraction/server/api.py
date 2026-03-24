"""FastAPI server for Refraction — serves Plotly chart specs
and receives edit events from the pywebview frontend."""

import json
import logging
import os
import tempfile
import threading
import uuid
from typing import Any, Optional

_log = logging.getLogger(__name__)

_server_thread: Optional[threading.Thread] = None
_app_ref = None  # reference to the App instance, set during startup
_PORT = 7331


def get_port() -> int:
    return _PORT


def start_server(app_instance=None) -> None:
    """Start the FastAPI server in a background daemon thread."""
    global _server_thread, _app_ref
    if _server_thread and _server_thread.is_alive():
        return  # Already running

    _app_ref = app_instance

    def _run():
        import uvicorn
        uvicorn.run(_make_app(), host="127.0.0.1", port=_PORT,
                    log_level="warning", access_log=False)

    _server_thread = threading.Thread(target=_run, daemon=True, name="plotter-server")
    _server_thread.start()


def _make_app():
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel

    class RenderRequest(BaseModel):
        chart_type: str
        kw: dict[str, Any]

    class EventRequest(BaseModel):
        event: str
        value: Any = None
        extra: dict[str, Any] = {}

    from fastapi.responses import JSONResponse
    from fastapi import Request

    API_KEY = os.environ.get("PLOTTER_API_KEY", "")

    api = FastAPI(title="Refraction API", version="1.0.0")

    api.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @api.middleware("http")
    async def check_auth(request: Request, call_next):
        """Require API key for non-local requests (if PLOTTER_API_KEY is set)."""
        # Use the actual socket IP, not the client-controlled Host header
        client_ip = request.client.host if request.client else ""
        if client_ip in ("127.0.0.1", "localhost", "::1"):
            return await call_next(request)
        if API_KEY and request.headers.get("x-api-key") != API_KEY:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)

    @api.post("/render")
    def render(req: RenderRequest):
        """Accept chart kwargs, return Plotly JSON."""
        try:
            spec_json = _build_spec(req.chart_type, req.kw)
            spec_dict = json.loads(spec_json)
            # Detect error responses from spec builders
            if isinstance(spec_dict, dict) and "error" in spec_dict:
                return JSONResponse({"ok": False, "error": spec_dict["error"]}, status_code=400)
            return {"ok": True, "spec": spec_dict}
        except Exception as e:
            _log.exception("Render failed for chart_type=%s", req.chart_type)
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    @api.post("/event")
    def handle_event(req: EventRequest):
        """Receive edit events from the frontend (e.g. title changed)."""
        try:
            _dispatch_event(req.event, req.value, req.extra)
            return {"ok": True}
        except Exception as e:
            _log.exception("Event dispatch failed for event=%s", req.event)
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    @api.post("/spec")
    def get_spec(req: RenderRequest):
        """Return raw Plotly JSON spec without rendering."""
        try:
            spec_json = _build_spec(req.chart_type, req.kw)
            spec_dict = json.loads(spec_json)
            if isinstance(spec_dict, dict) and "error" in spec_dict:
                return JSONResponse({"ok": False, "error": spec_dict["error"]}, status_code=400)
            return {"ok": True, "spec_json": spec_json}
        except Exception as e:
            _log.exception("Spec build failed for chart_type=%s", req.chart_type)
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    @api.get("/chart-types")
    def chart_types():
        """List available chart types."""
        return {
            "priority": ["bar", "grouped_bar", "line", "scatter"],
            "all": ["bar", "grouped_bar", "line", "scatter",
                    "box", "violin", "heatmap", "histogram",
                    "kaplan_meier", "two_way_anova", "before_after",
                    "subcolumn_scatter", "curve_fit", "column_stats",
                    "contingency", "repeated_measures", "chi_square_gof",
                    "stacked_bar", "bubble", "dot_plot", "bland_altman",
                    "forest_plot", "area_chart", "raincloud", "qq_plot",
                    "lollipop", "waterfall", "pyramid", "ecdf"]
        }

    @api.get("/health")
    def health():
        return {"status": "ok"}

    # ── File upload ──────────────────────────────────────────────
    from fastapi import UploadFile, File as FastAPIFile

    UPLOAD_DIR = os.path.join(tempfile.gettempdir(), "refraction-uploads")
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    @api.post("/upload")
    async def upload_file(file: UploadFile = FastAPIFile(...)):
        """Accept .xlsx/.xls/.csv upload; return server-side path."""
        ext = os.path.splitext(file.filename or "")[1].lower()
        if ext not in (".xlsx", ".xls", ".csv"):
            return {"ok": False, "error": f"Unsupported file type: {ext}"}
        contents = await file.read()
        if len(contents) > 10 * 1024 * 1024:  # 10 MB limit
            return {"ok": False, "error": "File too large (max 10 MB)"}
        # Fully sanitize filename: use only UUID + extension to prevent path traversal
        safe_name = f"{uuid.uuid4().hex}{ext}"
        dest = os.path.join(UPLOAD_DIR, safe_name)
        with open(dest, "wb") as f:
            f.write(contents)
        return {"ok": True, "path": dest, "filename": file.filename}

    # ── Phase 10a: Multi-panel layout ──────────────────────────────
    class LayoutRequest(BaseModel):
        panels: list[dict[str, Any]]
        title: str = ""
        export_width_mm: float = 183.0
        export_height_mm: float = 247.0
        gap_px: int = 16
        panel_labels: bool = True

    @api.post("/analyze-layout")
    def analyze_layout_endpoint(req: LayoutRequest):
        """Analyze a multi-panel layout, returning combined specs."""
        try:
            from refraction.analysis.layout import analyze_layout
            result = analyze_layout(
                req.panels,
                title=req.title,
                export_width_mm=req.export_width_mm,
                export_height_mm=req.export_height_mm,
                gap_px=req.gap_px,
                panel_labels=req.panel_labels,
            )
            return result
        except Exception as e:
            _log.exception("analyze-layout failed")
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    # ── Phase 10b: Curve models ──────────────────────────────────
    @api.get("/curve-models")
    def list_curve_models():
        """List all available curve fitting models by category."""
        from refraction.analysis.curve_models import list_models_by_category, model_count
        return {
            "ok": True,
            "models": list_models_by_category(),
            "total": model_count(),
        }

    class CurveFitRequest(BaseModel):
        x: list[float]
        y: list[float]
        model_name: str
        initial_params: list[float] | None = None

    @api.post("/curve-fit")
    def curve_fit_endpoint(req: CurveFitRequest):
        """Fit a curve model to X/Y data."""
        try:
            import numpy as _np
            from refraction.analysis.curve_fit import fit_curve
            result = fit_curve(
                _np.array(req.x),
                _np.array(req.y),
                req.model_name,
                initial_params=req.initial_params,
            )
            return {"ok": True, "fit": result.to_dict()}
        except ValueError as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)
        except Exception as e:
            _log.exception("curve-fit failed")
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    # ── Phase 10d: Column transforms ─────────────────────────────
    @api.get("/transforms")
    def list_transforms_endpoint():
        """List all available column transformations."""
        from refraction.analysis.transforms import list_transforms, transform_count
        return {
            "ok": True,
            "transforms": list_transforms(),
            "total": transform_count(),
        }

    class TransformRequest(BaseModel):
        data_path: str
        column: str | int
        operation: str
        params: dict[str, Any] = {}
        sheet: int | str = 0

    @api.post("/transform")
    def transform_endpoint(req: TransformRequest):
        """Apply a transform to a column; return path to new Excel file."""
        try:
            import pandas as _pd
            from refraction.analysis.transforms import transform_column

            df = _pd.read_excel(req.data_path, sheet_name=req.sheet)
            result_series = transform_column(df, req.column, req.operation, **req.params)

            # Write to new temp file
            new_df = df.copy()
            col_name = req.column if isinstance(req.column, str) else df.columns[req.column]
            new_df[f"{col_name}_{req.operation}"] = result_series

            dest = os.path.join(UPLOAD_DIR, f"{uuid.uuid4().hex}.xlsx")
            new_df.to_excel(dest, index=False)
            return {"ok": True, "path": dest, "column": f"{col_name}_{req.operation}"}
        except ValueError as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)
        except Exception as e:
            _log.exception("transform failed")
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    # ── Phase 10e: Project files ─────────────────────────────────
    class ProjectSaveRequest(BaseModel):
        panels: list[dict[str, Any]]
        layout: dict[str, Any] = {}
        settings: dict[str, Any] = {}
        metadata: dict[str, Any] = {}

    @api.post("/project/save")
    def project_save(req: ProjectSaveRequest):
        """Save a multi-panel project as .refract archive."""
        try:
            from refraction.io.project_v2 import save_project
            dest = os.path.join(UPLOAD_DIR, f"{uuid.uuid4().hex}.refract")
            path = save_project(
                dest,
                req.panels,
                metadata=req.metadata,
                layout=req.layout,
                settings=req.settings,
            )
            return {"ok": True, "path": path}
        except Exception as e:
            _log.exception("project save failed")
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    @api.post("/project/load")
    async def project_load(file: UploadFile = FastAPIFile(...)):
        """Upload and load a .refract project file."""
        try:
            from refraction.io.project_v2 import load_project
            ext = os.path.splitext(file.filename or "")[1].lower()
            if ext not in (".refract",):
                return JSONResponse(
                    {"ok": False, "error": f"Unsupported file type: {ext}"},
                    status_code=400,
                )
            contents = await file.read()
            dest = os.path.join(UPLOAD_DIR, f"{uuid.uuid4().hex}.refract")
            with open(dest, "wb") as f:
                f.write(contents)
            result = load_project(dest)
            # Don't return temp_dir in API response
            result.pop("temp_dir", None)
            return {"ok": True, "project": result}
        except Exception as e:
            _log.exception("project load failed")
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    # Serve React SPA static files if the build exists
    from fastapi.staticfiles import StaticFiles
    _project_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    web_dist = os.path.join(_project_root, "plotter_web", "dist")
    if os.path.isdir(web_dist):
        api.mount("/", StaticFiles(directory=web_dist, html=True), name="static")

    return api


_SPEC_BUILDERS: dict[str, tuple[str, str]] = {
    "bar":                ("refraction.specs.bar",               "build_bar_spec"),
    "grouped_bar":        ("refraction.specs.grouped_bar",       "build_grouped_bar_spec"),
    "line":               ("refraction.specs.line",              "build_line_spec"),
    "scatter":            ("refraction.specs.scatter",           "build_scatter_spec"),
    "box":                ("refraction.specs.box",               "build_box_spec"),
    "violin":             ("refraction.specs.violin",            "build_violin_spec"),
    "histogram":          ("refraction.specs.histogram",         "build_histogram_spec"),
    "dot_plot":           ("refraction.specs.dot_plot",          "build_dot_plot_spec"),
    "raincloud":          ("refraction.specs.raincloud",         "build_raincloud_spec"),
    "qq_plot":            ("refraction.specs.qq",                "build_qq_spec"),
    "ecdf":               ("refraction.specs.ecdf",              "build_ecdf_spec"),
    "before_after":       ("refraction.specs.before_after",      "build_before_after_spec"),
    "repeated_measures":  ("refraction.specs.repeated_measures", "build_repeated_measures_spec"),
    "subcolumn_scatter":  ("refraction.specs.subcolumn",         "build_subcolumn_spec"),
    "stacked_bar":        ("refraction.specs.stacked_bar",       "build_stacked_bar_spec"),
    "area_chart":         ("refraction.specs.area",              "build_area_spec"),
    "lollipop":           ("refraction.specs.lollipop",          "build_lollipop_spec"),
    "waterfall":          ("refraction.specs.waterfall",         "build_waterfall_spec"),
    "pyramid":            ("refraction.specs.pyramid",           "build_pyramid_spec"),
    "kaplan_meier":       ("refraction.specs.kaplan_meier",      "build_kaplan_meier_spec"),
    "heatmap":            ("refraction.specs.heatmap",           "build_heatmap_spec"),
    "bland_altman":       ("refraction.specs.bland_altman",      "build_bland_altman_spec"),
    "forest_plot":        ("refraction.specs.forest_plot",       "build_forest_plot_spec"),
    "bubble":             ("refraction.specs.bubble",            "build_bubble_spec"),
    "curve_fit":          ("refraction.specs.curve_fit",         "build_curve_fit_spec"),
    "column_stats":       ("refraction.specs.column_stats",      "build_column_stats_spec"),
    "contingency":        ("refraction.specs.contingency",       "build_contingency_spec"),
    "chi_square_gof":     ("refraction.specs.chi_square_gof",    "build_chi_square_gof_spec"),
    "two_way_anova":      ("refraction.specs.two_way_anova",     "build_two_way_anova_spec"),
}


def _build_spec(chart_type: str, kw: dict) -> str:
    """Route to the correct spec builder via lazy import."""
    if chart_type not in _SPEC_BUILDERS:
        return json.dumps({"error": f"Unknown chart type: {chart_type}"})
    module_name, fn_name = _SPEC_BUILDERS[chart_type]
    import importlib
    mod = importlib.import_module(module_name)
    builder = getattr(mod, fn_name)
    return builder(kw)


def _dispatch_event(event: str, value: Any, extra: dict) -> None:
    """Dispatch a frontend edit event back to the App form state."""
    if _app_ref is None:
        return
    app = _app_ref

    # Title changed in chart
    if event == "title_changed":
        _set_var(app, "title", value)

    # X-axis label changed
    elif event == "xlabel_changed":
        _set_var(app, "xlabel", value)

    # Y-axis label changed
    elif event == "ytitle_changed":
        _set_var(app, "ytitle", value)

    # Bar recolored
    elif event == "bar_recolored":
        # extra = {"group_index": int, "color": "#rrggbb"}
        pass  # Color sync TBD in Phase 3 polish

    # Y-axis range changed via drag
    elif event == "yrange_changed":
        # extra = {"ymin": float, "ymax": float}
        _set_var(app, "ymin", str(extra.get("ymin", "")))
        _set_var(app, "ymax", str(extra.get("ymax", "")))


def _set_var(app, key: str, value: str) -> None:
    """Safely set a tkinter StringVar on the main thread."""
    try:
        var = app._vars.get(key)
        if var is not None:
            app.after(0, lambda: var.set(value))
    except Exception:
        _log.debug("_set_var: could not set app var %r to %r", key, value, exc_info=True)
