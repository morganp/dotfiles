---
name: annual-planner
description: >
  Generate a complete annual task planner PDF notebook optimised for eink devices
  (reMarkable Paper Pro and similar). Use this skill whenever the user asks to
  create a planner, notebook, journal, or bullet journal PDF — especially for
  reMarkable, Kindle Scribe, Boox, or any eink device. Also trigger when the
  user wants to generate a year planner, daily pages, weekly spreads, or monthly
  calendars as a PDF. The skill produces a full-year PDF with a yearly overview,
  monthly calendar pages, weekly spreads, and daily dot-grid pages, all in a
  minimal Style-A aesthetic designed to look clean and write-friendly on eink.
---

# eink Annual Planner — Generation Skill

## Overview

This skill generates a complete annual bullet-journal PDF for eink devices.
The design comes from an iterative session with a user who settled on a clean
**"Style A — Minimal"** aesthetic: no filled backgrounds, hairline dividers,
light gray structural elements, and maximum open writing space.

Always ask the user for the **year** before generating. Everything else has
good defaults (see Parameters below).

---

## Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `year` | *ask user* | e.g. 2026 |
| `device` | reMarkable Paper Pro | See Device Sizes |
| `include_daily` | True | One page per calendar day |
| `include_weekly` | True | One spread per week (Mon–Sun) |
| `include_monthly` | True | One page per month |
| `include_yearly` | True | Year-at-a-glance overview page |
| `grid_spacing_mm` | 5 | Square grid cell size in mm |
| `output_filename` | `planner-{year}.pdf` | Saved to the workspace folder |

---

## Device Sizes

| Device | Page size (pt) | Notes |
|--------|---------------|-------|
| reMarkable Paper Pro (default) | 509 × 679 | 7.07" × 9.43" at 72dpi |
| reMarkable 2 | 504 × 672 | 7.00" × 9.33" at 72dpi |
| Kindle Scribe | 504 × 672 | Close to rM2 |
| A4 (generic) | 595 × 842 | Standard A4 |

For the reMarkable Paper Pro use `pagesize = (509, 679)` in reportlab.

---

## Design Specification

### Palette
```
TEXT_DARK   = "#1a1a1a"   # main text, dates, headings
TEXT_SUBTLE = "#aaaaaa"   # day labels, page numbers, secondary info
GRID_COLOR  = "#e0e0e0"   # square grid lines, hairline dividers
LINE_COLOR  = "#e8e8e8"   # ruled lines (weekly), soft separators
```

### Typography
- **Large numerals / month names**: serif font (Helvetica-Light or a system
  serif), weight 300, feels hand-press printed
- **Labels / day names / page numbers**: sans-serif, 6–8pt, letter-spacing 1–2
- **Never** use filled header backgrounds 

### Margins
```
MARGIN = 20  # points — applies to all four sides
```

### Grid
- Square grid (both horizontal and vertical lines), 5 mm spacing
- Line weight: 0.35pt, color: `GRID_COLOR`
- Used on: daily pages, monthly notes area, yearly notes strip
- **Weekly pages use ruled lines only** (horizontal, no vertical grid lines),
  spacing ~14pt, weight 0.4pt, color `LINE_COLOR`

### Event Colours (reMarkable Paper Pro supports colour e-ink)
```
C_WORK_HOL   = "#ffd5cc"   # light coral   — public / work holidays
C_SCHOOL_HOL = "#cce4ff"   # light sky-blue — school holidays
C_BDAY_FILL  = "#f0ddf7"   # light lavender — birthday cell fill
C_BDAY_DOT   = "#9060a0"   # dark purple    — birthday text / dots
```

**Priority**: work holiday > school holiday > birthday for cell fill colour.
A birthday on a holiday day still shows a small purple dot marker.

### Event Data Files (JSON, optional — place alongside the output PDF)

**`work_holidays.json`** — public/bank holidays (date ranges):
```json
[
  {"name": "Christmas Day", "start": "2026-12-25", "end": "2026-12-25"},
  {"name": "Christmas Break", "start": "2026-12-25", "end": "2026-12-26"}
]
```

**`school_holidays.json`** — school holiday date ranges (same format):
```json
[
  {"name": "Easter Break", "start": "2026-04-03", "end": "2026-04-17"},
  {"name": "Summer Holidays", "start": "2026-07-24", "end": "2026-09-04"}
]
```

**`birthdays.json`** — recurring yearly birthdays (month + day only):
```json
[
  {"name": "Alice", "month": 2, "day": 14},
  {"name": "Bob",   "month": 7, "day": 4}
]
```

All three files are **optional** — missing files are silently skipped.
Feb 29 birthdays are skipped in non-leap years automatically.

---

## Page Structures

### 1 — Yearly Overview

```
┌─────────────────────────────────────────┐
│ "2026"  (large serif, light weight)     │
│ ─────────────────────────────────────── │  ← hairline
│                                         │
│  Jan  Feb  Mar  Apr   ← 4 columns       │
│  May  Jun  Jul  Aug      × 3 rows       │
│  Sep  Oct  Nov  Dec                     │
│  (12 mini month calendars, 4×3 grid)    │
│                                         │
│ ─────────────────────────────────────── │
│ INTENTIONS & THEMES  _______________    │
│ _______________________________________│
└─────────────────────────────────────────┘
```

- Mini calendar: month name (bold, 8pt sans), day initials row (S M T W T F S,
  6pt subtle), date numbers (6.5pt, start='middle')
- Today's date gets a filled circle highlight

### 2 — Monthly Page

```
┌─────────────────────────────────────────┐
│ "February"  2026  (serif light, 22pt)   │
│ ─────────────────────────────────────── │  ← hairline
│                                         │
│ SUN  MON  TUE  WED  THU  FRI  SAT      │
│  1    2    3    4    5    6    7         │
│  8    9   10   11   12   13   14        │
│  …                                      │
│  (dates sit top-left of each cell       │
│   leaving the cell body for writing)    │
│                                         │
│ ─────────────────────────────────────── │
│ NOTES  [square grid fills remaining]   │
└─────────────────────────────────────────┘
```

**Key detail**: dates are anchored **top-left** of each calendar cell, small
(~8pt), leaving the rest of the cell for the user to write events/notes.
Cell dividers are hairlines (0.25pt). Today's date gets a small filled circle.

### 3 — Weekly Spread

```
┌─────────────────────────────────────┬──────────┐
│ WEEK 09   Feb 24 — Mar 1, 2026      │          │
│ ────────────────────────────────────│          │
│ MON │ ○ ______  ○ ______  ○ ______  │  SAT  1  │
│  24 │ ○ ______  ○ ______             │ Mar      │
│─────┼────────────────────────────── │ ○ ─────  │
│ TUE │ ○ ______  ○ ______  ○ ______  │ ○ ─────  │
│  25 │ ○ ______  ○ ______             │ ○ ─────  │
│─────┼────────────────────────────── ├──────────│
│ WED │ ○ ______  ○ ______  ○ ______  │  SUN  2  │
│  26 │ ○ ______  ○ ______             │ Mar      │
│─────┼────────────────────────────── │ ○ ─────  │
│ THU │ ○ ______  ○ ______  ○ ______  │ ○ ─────  │
│  27 │ ○ ______  ○ ______             │ ○ ─────  │
│─────┼────────────────────────────── │          │
│ FRI │ ○ ______  ○ ______  ○ ______  │          │
│  28 │ ○ ______  ○ ______             │          │
└─────┴────────────────────────────── ┴──────────┘
```

**Layout decisions (do not change)**:
- **5 weekday rows** stacked top-to-bottom (Mon → Fri), each equal height,
  filling 70% of the page width
- Each row has a **left badge** (~46pt wide): day abbreviation (6.5pt sans,
  subtle, letter-spacing 1.5) on top, date number (15pt serif light) below;
  a thin vertical hairline separates the badge from the writing area
- Each row contains **5 ruled lines** with a bullet dot (○, 2.5pt open circle)
  to the left of each line — evenly distributed across the full row height
- Row dividers: 0.35pt `GRID_COLOR` hairlines between days
- **1 weekend column** (30%) on the right, split mid-height: SAT top half,
  SUN bottom half, each with **3 ruled lines** with bullet dots
- Thick divider before weekend column: 0.5pt `TEXT_DARK`
- Header: "WEEK XX" (7.5pt sans, subtle, letter-spacing 2) + date range (11pt
  serif light), followed by a 0.5pt hairline. **No background fill.**
- Today's date number is rendered slightly bolder/darker than other days

**Python geometry (page_weekly)**:
```python
badge_w  = 46            # left badge width in points
day_h    = content_h / 5 # each row height (content_h = end_y - start_y)
line_gap = day_h / 6     # 5 lines with equal breathing room top & bottom

for i in range(5):
    dy = start_y + i * day_h
    if i > 0:
        hline(c, M, dy, M + main_w, C_GRID, 0.35)           # row divider
    # badge
    txt(c, M + 5, dy + 12, DAY_LABEL[i], F_SANS_B, 6.5, C_SUBTLE, cs=1.5)
    txt(c, M + 5, dy + 28, date.day, F_SERIF, 15, ...)
    vline(c, M + badge_w, dy, dy + day_h, C_GRID, 0.3)      # badge separator
    # 5 bullet lines
    for l in range(5):
        ly = dy + line_gap * (l + 0.5)
        open_circle(c, M + badge_w + 10, ly)
        hline(c, M + badge_w + 20, ly, M + main_w - 6, C_LINE, 0.4)
```

### 4 — Daily Page

```
┌─────────────────────────────────────────┐
│ FRI  27  FEBRUARY                       │
│          2026                           │
│ ─────────────────────────────────────── │  ← hairline (0.5pt)
│                                         │
│  · · · · · · · · · · · · · · · · · ·   │
│  · · · · · · · (square grid) · · · ·   │
│  · · · · · · · · · · · · · · · · · ·   │
│                                         │
│                    01                   │  ← page number
└─────────────────────────────────────────┘
```

**Header layout**:
- "FRI" — 8pt sans, subtle, letter-spacing 1.5, top-left
- "27"  — 18pt serif, light weight, beside FRI
- "FEBRUARY" — 7.5pt sans, subtle, letter-spacing 1.5, stacked above "2026"
- Single 0.5pt hairline ~26pt from top
- Square grid starts ~38pt from top, fills to 65pt from bottom
- Page number centred, 7.5pt, subtle, at the very bottom

---

## Event Highlighting Per View

### Yearly (mini calendars)
- **Work holiday**: coral filled circle behind the date number
- **School holiday**: sky-blue filled circle behind the date number
- **Birthday**: lavender filled circle + small purple dot (upper-right)
- **Today**: dark filled circle (always takes priority)
- Colour legend at bottom-right of page: ■ Work holiday  ■ School holiday  ● Birthday

### Monthly (full calendar cells)
- Cell background filled with event colour (work > school > birthday priority)
- Holiday name shown below the date in 4.5pt text (truncated to ~10 chars)
- Birthday names shown with a small purple dot marker, stacked below holiday name

### Weekly (row per day)
- Badge (left column) filled with event colour
- Holiday name shown in badge below the date number (5.5pt, up to 2 lines)
- Birthday names shown in badge below holiday name, with purple dot marker
- Weekend column halves (SAT/SUN) receive the same fill treatment

### Daily
- Coloured strip(s) inserted between the header hairline and the square grid
- Work or school holiday: coral/blue strip with holiday name
- Birthday: lavender strip with "Birthday  —  Name"
- Up to 2 strips shown; grid starts immediately below

---

## Python Generation Approach

Use **reportlab** to generate the PDF.

```python
pip install reportlab --break-system-packages
```

### Key reportlab patterns

```python
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor

# Page setup
W, H = 509, 679          # reMarkable Paper Pro
MARGIN = 20
c = canvas.Canvas("planner-2026.pdf", pagesize=(W, H))

# Colors
TEXT_DARK   = HexColor("#1a1a1a")
TEXT_SUBTLE = HexColor("#aaaaaa")
GRID_COLOR  = HexColor("#e0e0e0")
LINE_COLOR  = HexColor("#e8e8e8")

# Draw hairline
c.setStrokeColor(GRID_COLOR)
c.setLineWidth(0.5)
c.line(MARGIN, H - 26, W - MARGIN, H - 26)

# Draw square grid
def draw_square_grid(c, x, y, w, h, spacing_pt, color):
    c.setStrokeColor(color)
    c.setLineWidth(0.35)
    gx = x
    while gx <= x + w:
        c.line(gx, y, gx, y + h)
        gx += spacing_pt
    gy = y
    while gy <= y + h:
        c.line(x, gy, x + w, gy)
        gy += spacing_pt

# Draw ruled lines only (weekly)
def draw_ruled_lines(c, x, y, w, h, spacing_pt, color):
    c.setStrokeColor(color)
    c.setLineWidth(0.4)
    gy = y + spacing_pt
    while gy <= y + h:
        c.line(x, gy, x + w, gy)
        gy += spacing_pt

# 5mm grid spacing in points
GRID_PT = 5 / 25.4 * 72   # ≈ 14.17 pt

# Serif light text
c.setFont("Helvetica-Light", 18)   # use Helvetica-Light for "light weight" feel
                                    # or register a proper thin font if available
c.setFillColor(TEXT_DARK)
c.drawString(x, y, "27")

# Subtle small caps label
c.setFont("Helvetica", 8)
c.setFillColor(TEXT_SUBTLE)
# letter-spacing: draw char by char or use PDFgen's charSpace
c.setCharSpace(1.5)
c.drawString(x, y, "FRI")
c.setCharSpace(0)   # reset

c.showPage()   # next page
c.save()
```

### Recommended page generation order

```
1. Yearly overview (1 page)
2. For each month January → December:
   a. Monthly overview page (1 page)
   b. Weekly spreads for that month (4–5 pages)
   c. Daily pages for each day of that month
```

This gives a natural navigation flow when swiping through on a reMarkable.

### Week number calculation

```python
import datetime
def week_number(date):
    return date.isocalendar()[1]

def week_label(monday):
    sunday = monday + datetime.timedelta(days=6)
    if monday.month == sunday.month:
        return f"{monday.strftime('%b')} {monday.day} — {sunday.day}"
    else:
        return f"{monday.strftime('%b')} {monday.day} — {sunday.strftime('%b')} {sunday.day}"
```

### Mini calendar helper (for yearly page)

```python
import calendar

def draw_mini_cal(c, sx, sy, cw, month, year, text_color, subtle_color):
    month_names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec']
    day_initials = ['S','M','T','W','T','F','S']
    days_in_month = calendar.monthrange(year, month)[1]
    first_weekday = calendar.monthrange(year, month)[0]   # 0=Mon in Python
    # Convert to Sun-start: Sunday = 0
    first_col = (first_weekday + 1) % 7

    cell_w = cw / 7
    cell_h = cell_w * 1.15

    # Month name
    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(text_color)
    c.drawCentredString(sx + cw/2, sy + 8, month_names[month-1])

    # Day initials
    c.setFont("Helvetica", 5.5)
    c.setFillColor(subtle_color)
    for d, label in enumerate(day_initials):
        c.drawCentredString(sx + d*cell_w + cell_w/2, sy + 19, label)

    # Dates
    c.setFont("Helvetica", 6)
    c.setFillColor(text_color)
    day = 1
    for row in range(6):
        for col in range(7):
            idx = row * 7 + col
            if idx >= first_col and day <= days_in_month:
                cx = sx + col*cell_w + cell_w/2
                cy = sy + 28 + row*cell_h
                c.drawCentredString(cx, cy, str(day))
                day += 1
            if day > days_in_month:
                break
```

---

## Output

Save the finished PDF to the **workspace folder** (`/sessions/.../mnt/<folder>/`)
and present it to the user with a `computer://` link.

A full year (365 daily + 52 weekly + 12 monthly + 1 yearly) typically produces
a ~430-page PDF around 2–5 MB.

---

## Common Customisations

- **Cover page**: add a simple title page with the year and the user's name
  before the yearly overview
- **Habit tracker**: add a row of 7 small checkboxes at the bottom of each
  daily page (Style B feature, easy to bolt on)
- **Custom date range**: user may want only part of a year — accept
  `start_date` / `end_date` parameters and skip pages outside the range
- **Landscape weekly**: some users prefer a landscape weekly spread; rotate
  the page 90° for weekly pages only
