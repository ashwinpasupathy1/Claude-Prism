"""pywebview panel for rendering Plotly charts inside the Tk window.

On macOS, pywebview uses WKWebView which embeds cleanly.
The HTML page loads Plotly.js from CDN and renders the spec.
Edit events are posted back to the FastAPI /event endpoint.
"""

from __future__ import annotations
import json
import threading
import tkinter as tk


# HTML template served to pywebview
_HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body {{ margin: 0; padding: 0; background: white; }}
  #plot {{ width: 100vw; height: 100vh; }}
</style>
<script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
</head>
<body>
  <div id="plot"></div>
  <script>
    const API_BASE = "http://127.0.0.1:{PORT}";

    async function renderChart(chartType, kw) {{
      try {{
        const resp = await fetch(API_BASE + "/render", {{
          method: "POST",
          headers: {{"Content-Type": "application/json"}},
          body: JSON.stringify({{chart_type: chartType, kw: kw}})
        }});
        const data = await resp.json();
        if (!data.ok) {{
          console.error("Render error:", data.error);
          return;
        }}
        const spec = data.spec;
        Plotly.newPlot("plot", spec.data, spec.layout, {{
          responsive: true,
          displayModeBar: true,
          editable: true,
        }});

        // Listen for editable title/axis changes
        const plotDiv = document.getElementById("plot");
        plotDiv.on("plotly_relayout", function(update) {{
          if (update["title.text"] !== undefined) {{
            postEvent("title_changed", update["title.text"]);
          }}
          if (update["xaxis.title.text"] !== undefined) {{
            postEvent("xlabel_changed", update["xaxis.title.text"]);
          }}
          if (update["yaxis.title.text"] !== undefined) {{
            postEvent("ytitle_changed", update["yaxis.title.text"]);
          }}
          if (update["yaxis.range[0]"] !== undefined) {{
            postEvent("yrange_changed", null, {{
              ymin: update["yaxis.range[0]"],
              ymax: update["yaxis.range[1]"]
            }});
          }}
        }});
      }} catch (e) {{
        console.error("renderChart error:", e);
      }}
    }}

    async function postEvent(event, value, extra) {{
      try {{
        await fetch(API_BASE + "/event", {{
          method: "POST",
          headers: {{"Content-Type": "application/json"}},
          body: JSON.stringify({{event, value, extra: extra || {{}}}})
        }});
      }} catch (e) {{
        console.error("postEvent error:", e);
      }}
    }}

    // Called from Python via webview.evaluate_js
    window.plotterRender = renderChart;
  </script>
</body>
</html>"""


class PlotterWebView:
    """Wraps a pywebview window for embedding Plotly charts.

    Usage:
        pv = PlotterWebView(parent_frame, port=7331)
        pv.show()
        pv.render("bar", kw_dict)
    """

    def __init__(self, parent: tk.Frame, port: int = 7331):
        self._parent = parent
        self._port = port
        self._window = None
        self._ready = threading.Event()

    def show(self) -> bool:
        """Create and embed the webview. Returns True on success."""
        try:
            import webview

            html = _HTML_TEMPLATE.format(PORT=self._port)

            def _create():
                self._window = webview.create_window(
                    "Claude Plotter Chart",
                    html=html,
                    width=800, height=600,
                    resizable=True,
                    frameless=False,
                )
                self._ready.set()
                webview.start()

            t = threading.Thread(target=_create, daemon=True)
            t.start()
            self._ready.wait(timeout=5.0)
            return self._window is not None

        except ImportError:
            return False
        except Exception:
            return False

    def render(self, chart_type: str, kw: dict) -> bool:
        """Call JavaScript to render a chart. Returns True on success."""
        if self._window is None:
            return False
        try:
            kw_json = json.dumps(kw)
            js = f"window.plotterRender('{chart_type}', {kw_json})"
            self._window.evaluate_js(js)
            return True
        except Exception:
            return False

    def destroy(self) -> None:
        """Close the webview window."""
        try:
            if self._window is not None:
                self._window.destroy()
        except Exception:
            pass
