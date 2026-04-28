#!/usr/bin/env python3
"""Format fixed-width terminal tables from JSON.

Input JSON on stdin:
{
  "headers": ["Status", "Check", "Result"],
  "rows": [
    ["PASS", "Protocol", "YAML matches spec."],
    [{"text": "MISMATCH", "color": "red"}, "Width", "Spec says 8b; YAML has 9b."]
  ]
}

The formatter strips ANSI escape sequences when measuring visible width, so
pre-colored cell content remains aligned.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from typing import Iterable


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
RESET = "\x1b[0m"
COLORS = {
    "black": "\x1b[30m",
    "red": "\x1b[31m",
    "green": "\x1b[32m",
    "yellow": "\x1b[33m",
    "blue": "\x1b[34m",
    "magenta": "\x1b[35m",
    "cyan": "\x1b[36m",
    "white": "\x1b[37m",
    "bright_black": "\x1b[90m",
    "bright_red": "\x1b[91m",
    "bright_green": "\x1b[92m",
    "bright_yellow": "\x1b[93m",
    "bright_blue": "\x1b[94m",
    "bright_magenta": "\x1b[95m",
    "bright_cyan": "\x1b[96m",
    "bright_white": "\x1b[97m",
}


@dataclass(frozen=True)
class Cell:
    text: str
    color: str | None = None

    def render(self, color_enabled: bool) -> str:
        if not color_enabled or not self.color:
            return self.text
        color = COLORS.get(self.color)
        return f"{color}{self.text}{RESET}" if color else self.text


def visible_len(value: str) -> int:
    return len(ANSI_RE.sub("", value))


def pad(value: str, width: int) -> str:
    return value + (" " * (width - visible_len(value)))


def normalize_cell(value: object) -> Cell:
    if isinstance(value, dict):
        if "text" not in value:
            raise ValueError("cell object must contain a 'text' field")
        color = value.get("color")
        if color is not None and not isinstance(color, str):
            raise ValueError("cell 'color' field must be a string")
        return Cell(str(value["text"]), color)
    return Cell(str(value))


def normalize_rows(rows: Iterable[Iterable[object]]) -> list[list[Cell]]:
    return [[normalize_cell(cell) for cell in row] for row in rows]


def render_cells(rows: Iterable[Iterable[Cell]], color_enabled: bool) -> list[list[str]]:
    return [[cell.render(color_enabled) for cell in row] for row in rows]


def format_table(headers: list[Cell], rows: list[list[Cell]], color_enabled: bool) -> str:
    if not headers:
        raise ValueError("headers must not be empty")
    if any(len(row) != len(headers) for row in rows):
        raise ValueError("every row must have the same number of columns as headers")

    rendered_headers = render_cells([headers], color_enabled)[0]
    rendered_rows = render_cells(rows, color_enabled)
    all_rows = [rendered_headers] + rendered_rows
    widths = [max(visible_len(row[i]) for row in all_rows) for i in range(len(headers))]

    def border() -> str:
        return "+" + "+".join("-" * (width + 2) for width in widths) + "+"

    def render_row(row: list[str]) -> str:
        return "| " + " | ".join(pad(row[i], widths[i]) for i in range(len(headers))) + " |"

    lines = [border(), render_row(rendered_headers), border()]
    lines.extend(render_row(row) for row in rendered_rows)
    lines.append(border())
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Format fixed-width terminal tables.")
    parser.add_argument("--no-color", action="store_true", help="Ignore semantic color fields.")
    args = parser.parse_args()

    payload = json.load(sys.stdin)
    headers = [normalize_cell(header) for header in payload["headers"]]
    rows = normalize_rows(payload["rows"])
    print(format_table(headers, rows, color_enabled=not args.no_color))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
