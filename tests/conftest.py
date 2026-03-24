"""
conftest.py
===========
Shared pytest fixtures for all Refraction test suites.

Provides temporary Excel file builders as fixtures with automatic cleanup.
"""

import os
import sys
import tempfile
from collections import Counter
from typing import Dict, List, Optional

import numpy as np
import pandas as pd
import pytest

# Ensure refraction package is importable
_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ROOT = os.path.dirname(_HERE)
if _PROJECT_ROOT not in sys.path:
    sys.path.insert(0, _PROJECT_ROOT)


# ---------------------------------------------------------------------------
# Excel file builder helpers (return path, caller manages cleanup)
# ---------------------------------------------------------------------------

def _write_bar_excel(groups: Dict[str, list], path: str) -> str:
    """Flat header layout: Row 0 = group names, Rows 1+ = values.
    Groups may have different lengths; shorter columns are NaN-padded."""
    names = list(groups.keys())
    max_n = max(len(v) for v in groups.values())
    rows = [names]
    for i in range(max_n):
        rows.append([
            float(groups[n][i]) if i < len(groups[n]) else None
            for n in names
        ])
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_xy_excel(x: list, y_series: Dict[str, list], path: str) -> str:
    """XY layout: Row 0 = [X-label, series names], Rows 1+ = [x, y1, y2, ...]."""
    header = ["X"] + list(y_series.keys())
    rows = [header]
    for i, xv in enumerate(x):
        row = [float(xv)]
        for name in y_series:
            row.append(float(y_series[name][i]) if i < len(y_series[name]) else None)
        rows.append(row)
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_grouped_excel(categories: List[str], subgroups: List[str],
                         data: Dict[str, Dict[str, list]], path: str) -> str:
    """Grouped bar layout: Row 0 = categories (repeated), Row 1 = subgroups, Rows 2+ = data."""
    max_n = max(
        len(data[cat].get(sub, []))
        for cat in categories for sub in subgroups
    ) if categories and subgroups else 1
    row1 = [cat for cat in categories for _ in subgroups]
    row2 = [sub for _ in categories for sub in subgroups]
    rows = [row1, row2]
    for i in range(max_n):
        rows.append([
            float(data[cat].get(sub, [None] * max_n)[i])
            if i < len(data[cat].get(sub, [])) else None
            for cat in categories for sub in subgroups
        ])
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_km_excel(groups: Dict[str, Dict[str, list]], path: str) -> str:
    """KM layout: Row 0 = group names (each spans 2 cols),
    Row 1 = Time/Event headers, Rows 2+ = data."""
    names = list(groups.keys())
    row1 = [n for n in names for _ in range(2)]
    row2 = ["Time", "Event"] * len(names)
    max_n = max(len(groups[n]["time"]) for n in names)
    rows = [row1, row2]
    for i in range(max_n):
        row = []
        for n in names:
            t = groups[n]["time"]
            e = groups[n]["event"]
            row += [float(t[i]) if i < len(t) else None,
                    float(e[i]) if i < len(e) else None]
        rows.append(row)
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_heatmap_excel(matrix: list, row_labels: List[str],
                         col_labels: List[str], path: str) -> str:
    """Heatmap layout: top-left blank, row 0 = col labels, col A = row labels."""
    rows = [[""] + col_labels]
    for rl, row in zip(row_labels, matrix):
        rows.append([rl] + [float(v) for v in row])
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_contingency_excel(row_labels: List[str], col_labels: List[str],
                             matrix: list, path: str) -> str:
    """Contingency layout: top-left blank, row 0 = outcomes, col A = groups."""
    rows = [[""] + col_labels]
    for rl, row in zip(row_labels, matrix):
        rows.append([rl] + [int(v) for v in row])
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


def _write_forest_excel(studies: List[str], effects: List[float],
                        ci_lo: List[float], ci_hi: List[float],
                        path: str) -> str:
    """Forest plot: header row + Study/Effect/CI_lo/CI_hi columns."""
    df = pd.DataFrame({
        "Study": studies,
        "Effect": [float(v) for v in effects],
        "CI_lo": [float(v) for v in ci_lo],
        "CI_hi": [float(v) for v in ci_hi],
    })
    df.to_excel(path, index=False)
    return path


def _write_bland_altman_excel(method_a: list, method_b: list, path: str) -> str:
    """Bland-Altman: Row 0 = method names, Rows 1+ = paired values."""
    rows = [["Method A", "Method B"]]
    for a, b in zip(method_a, method_b):
        rows.append([float(a), float(b)])
    pd.DataFrame(rows).to_excel(path, index=False, header=False)
    return path


# ---------------------------------------------------------------------------
# Pytest fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def tmp_excel():
    """Yield a factory that creates temp .xlsx files and cleans them up after the test."""
    created = []

    def _make():
        t = tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False)
        t.close()
        created.append(t.name)
        return t.name

    yield _make

    for path in created:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


@pytest.fixture
def bar_data(tmp_excel):
    """Factory fixture: bar_data({"A": [1,2,3], "B": [4,5,6]}) -> path to xlsx."""
    def _build(groups: Dict[str, list]) -> str:
        path = tmp_excel()
        return _write_bar_excel(groups, path)
    return _build


@pytest.fixture
def xy_data(tmp_excel):
    """Factory fixture: xy_data([1,2,3], {"Series": [4,5,6]}) -> path to xlsx."""
    def _build(x: list, y_series: Dict[str, list]) -> str:
        path = tmp_excel()
        return _write_xy_excel(x, y_series, path)
    return _build


@pytest.fixture
def grouped_data(tmp_excel):
    """Factory fixture for grouped bar data."""
    def _build(categories, subgroups, data):
        path = tmp_excel()
        return _write_grouped_excel(categories, subgroups, data, path)
    return _build


@pytest.fixture
def km_data(tmp_excel):
    """Factory fixture for Kaplan-Meier data."""
    def _build(groups):
        path = tmp_excel()
        return _write_km_excel(groups, path)
    return _build


@pytest.fixture
def heatmap_data(tmp_excel):
    """Factory fixture for heatmap data."""
    def _build(matrix, row_labels, col_labels):
        path = tmp_excel()
        return _write_heatmap_excel(matrix, row_labels, col_labels, path)
    return _build


@pytest.fixture
def contingency_data(tmp_excel):
    """Factory fixture for contingency table data."""
    def _build(row_labels, col_labels, matrix):
        path = tmp_excel()
        return _write_contingency_excel(row_labels, col_labels, matrix, path)
    return _build


@pytest.fixture
def forest_data(tmp_excel):
    """Factory fixture for forest plot data."""
    def _build(studies, effects, ci_lo, ci_hi):
        path = tmp_excel()
        return _write_forest_excel(studies, effects, ci_lo, ci_hi, path)
    return _build


@pytest.fixture
def bland_altman_data_fixture(tmp_excel):
    """Factory fixture for Bland-Altman data."""
    def _build(method_a, method_b):
        path = tmp_excel()
        return _write_bland_altman_excel(method_a, method_b, path)
    return _build
