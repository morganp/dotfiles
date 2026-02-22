---
name: verilog-lint
description: Lint and validate Verilog/SystemVerilog (RTL/HDL) code using Verilator and Verible. Trigger when the user asks to generate RTL, write Verilog or SystemVerilog, check HDL syntax, lint hardware description code, fix Verilog errors, or when they mention modules, always blocks, wire/reg/logic declarations, clocks, resets, FSMs, synthesis, flip-flops, or any digital hardware design topic.
---

# Verilog Lint Skill

## Overview

This skill lints Verilog (`.v`) and SystemVerilog (`.sv`) code using two complementary open-source tools:

- **Verilator** (`--lint-only -Wall`) — semantic correctness: undeclared signals, width mismatches, undriven/unused nets, blocking-in-always issues
- **Verible** (`verible-verilog-lint`) — style and formatting: naming conventions, whitespace, port alignment

When Claude generates RTL code, this skill closes the feedback loop: write → lint → fix → re-lint, up to **3 automatic iterations**, until both tools report clean. If errors persist after 3 passes, the remaining issues are surfaced to the user with a diagnostic table.

---

## Workflow

### Step 1 — Determine file type

- `.sv` or `SystemVerilog` → use `verilator --lint-only -Wall --sv`
- `.v` or `Verilog` → use `verilator --lint-only -Wall`
- Default to `.sv` / SystemVerilog when generating new code (preferred modern standard)

### Step 2 — Check tool availability

```bash
which verilator      # Semantic linter
which verible-verilog-lint  # Style linter
```

If either is missing, print the appropriate install instructions (see **Tool Installation**) and ask the user to install before proceeding.

### Step 3 — Write code to a temp file

```bash
# Use a deterministic temp path based on module name
TMPFILE="/tmp/claude_rtl_<module_name>.sv"
```

Write the Verilog/SystemVerilog to this file using the Write tool.

### Step 4 — Run Verilator (semantic pass)

```bash
verilator --lint-only -Wall --sv /tmp/claude_rtl_<name>.sv 2>&1
# For plain Verilog (not SystemVerilog):
verilator --lint-only -Wall /tmp/claude_rtl_<name>.sv 2>&1
```

- Exit code `0` = clean
- Any `%Error` lines = must fix before proceeding
- `%Warning-*` lines = fix if possible, flag to user if not

### Step 5 — Run Verible (style pass)

```bash
verible-verilog-lint /tmp/claude_rtl_<name>.sv
```

- Exit code `0` = clean
- Non-zero = style violations; parse `filename:line:col: rule-name` format

### Step 6 — Auto-fix loop (max 3 iterations)

```
iteration = 1
while errors exist and iteration <= 3:
    parse error messages → identify lines → apply fixes to code
    re-write temp file
    re-run Verilator + Verible
    iteration++

if clean: report ✓ and output final code
if still errors: report diagnostic table, stop
```

### Step 7 — Report results

See **Output Format** section.

---

## Tool Reference

### Verilator

**Purpose:** Semantic and RTL correctness checking (acts like a synthesizer front-end).

**Flags:**

| Flag | Effect |
|------|--------|
| `--lint-only` | Check only, do not compile/simulate |
| `-Wall` | Enable all warnings |
| `--sv` | Parse as SystemVerilog (IEEE 1800-2017) |
| `--top-module <name>` | Specify top module if multiple in file |
| `--no-timing` | Suppress timing construct warnings |
| `-Wno-UNUSED` | Suppress unused-signal warnings (use sparingly) |

**Output format:**
```
%Error: file.sv:10:5: Cannot find variable: 'data_out'
%Warning-WIDTH: file.sv:22:8: Operator ASSIGN expects 8 bits, but input is 4 bits
%Warning-UNUSED: file.sv:5:3: Signal is not used: 'clk_unused'
```

### Verible

**Purpose:** Style enforcement — naming, formatting, port alignment.

**Flags:**

| Flag | Effect |
|------|--------|
| (none) | Lint with default Google style rules |
| `--rules=+module-filename` | Enable specific rule |
| `--rules=-underscore-numbers` | Disable specific rule |
| `--rules_config=<file>` | Load rules from config file |
| `--output_format=github` | GitHub Actions annotation format |

**Output format:**
```
file.sv:8:1: module-filename: Module name 'mymod' does not match filename 'claude_rtl_mymod.sv'
file.sv:14:3: always-ff-non-blocking: Use non-blocking assignments (<=) in always_ff blocks
```

---

## Error Interpretation Guide

### Verilator errors

| Error | Meaning | Fix |
|-------|---------|-----|
| `%Error: Cannot find variable: 'x'` | Signal `x` used but never declared | Add `wire`/`logic` declaration |
| `%Warning-WIDTH` | Bit width mismatch on assignment or operator | Match widths or add explicit cast |
| `%Warning-UNUSED` | Signal declared but never read | Remove it or connect it |
| `%Warning-UNDRIVEN` | Signal never assigned | Drive it from logic or remove |
| `%Warning-BLKANDNBLK` | Mixed blocking/non-blocking in same always | Use `<=` consistently in `always_ff` |
| `%Warning-COMBDLY` | Blocking assignment in combinational always | Use `=` in `always_comb`, `<=` in `always_ff` |
| `%Warning-MULTIDRIVEN` | Signal driven from multiple always blocks | Consolidate to single always block |
| `%Warning-IMPLICIT` | Implicit net declaration | Declare all nets explicitly |
| `%Error: Unsized constant` | Integer literal without bit width | Use `8'hFF` instead of `8'hFF` |

### Verible style rules

| Rule | Meaning | Fix |
|------|---------|-----|
| `module-filename` | Module name ≠ filename | Rename module or file to match |
| `always-ff-non-blocking` | Blocking `=` in `always_ff` | Change to `<=` |
| `always-comb-blocking` | Non-blocking `<=` in `always_comb` | Change to `=` |
| `no-tabs` | Tab characters in source | Replace with spaces |
| `port-name-suffix` | Port naming convention violation | Follow `_i`/`_o` or similar convention |
| `line-length` | Line too long | Break long lines |

---

## Common RTL Patterns

Use these as the basis for generated code to avoid common lint errors.

### Synchronous reset flip-flop (SystemVerilog)

```systemverilog
module dff #(
  parameter int WIDTH = 8
) (
  input  logic             clk_i,
  input  logic             rst_ni,  // active-low reset
  input  logic [WIDTH-1:0] d_i,
  output logic [WIDTH-1:0] q_o
);

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      q_o <= '0;
    end else begin
      q_o <= d_i;
    end
  end

endmodule
```

### Combinational logic (SystemVerilog)

```systemverilog
module mux2 #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic             sel_i,
  output logic [WIDTH-1:0] y_o
);

  always_comb begin
    if (sel_i) begin
      y_o = b_i;
    end else begin
      y_o = a_i;
    end
  end

endmodule
```

### Simple FSM (SystemVerilog)

```systemverilog
module fsm (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic trigger_i,
  output logic active_o
);

  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    RUN   = 2'b01,
    DONE  = 2'b10
  } state_e;

  state_e state_q, state_d;

  // State register
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  // Next-state logic
  always_comb begin
    state_d  = state_q;
    active_o = 1'b0;

    unique case (state_q)
      IDLE: begin
        if (trigger_i) state_d = RUN;
      end
      RUN: begin
        active_o = 1'b1;
        state_d  = DONE;
      end
      DONE: begin
        state_d = IDLE;
      end
      default: state_d = IDLE;
    endcase
  end

endmodule
```

### Parameterized counter

```systemverilog
module counter #(
  parameter int WIDTH = 4
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             en_i,
  output logic [WIDTH-1:0] count_o
);

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      count_o <= '0;
    end else if (en_i) begin
      count_o <= count_o + 1'b1;
    end
  end

endmodule
```

---

## Output Format

### Clean pass

```
✓ Lint clean (Verilator + Verible, 1 pass)

module counter ( ... )
```

Show the final code in a fenced ` ```systemverilog ` block.

### Errors fixed automatically

```
⚙ Pass 1: 2 Verilator errors, 1 Verible warning — fixing...
  - Line 12: declared missing wire `data_out` as `logic [7:0]`
  - Line 18: changed blocking `=` to non-blocking `<=` in always_ff
  - Line 5: renamed module to match filename convention

✓ Lint clean after 2 passes
```

Then show the corrected code.

### Unresolved errors (after 3 passes)

Show a diagnostic table:

```
✗ 2 errors remain after 3 fix attempts:

| Line | Tool       | Severity | Rule / Message                              | Suggested Fix                  |
|------|------------|----------|---------------------------------------------|-------------------------------|
| 24   | Verilator  | Error    | Cannot find variable: 'bus_data'            | Declare as `logic [7:0] bus_data` |
| 31   | Verible    | Warning  | always-ff-non-blocking: use <= in always_ff | Change `=` to `<=`            |
```

Then ask the user how to proceed.

---

## Tool Installation

Check which tools are present before running:

```bash
which verilator && which verible-verilog-lint
```

If a tool is missing, surface the correct install command based on OS:

```bash
uname -s  # Darwin = macOS, Linux = check distro
```

### macOS

```bash
# Verilator
brew install verilator

# Verible
brew tap chipsalliance/verible
brew install verible
```

### Linux — Debian / Ubuntu

```bash
# Verilator (system package, may be older)
sudo apt install verilator

# Verilator (latest, build from source if needed)
# https://verilator.org/guide/latest/install.html

# Verible — check if in apt first, else use GitHub release
sudo apt install verible 2>/dev/null || true

# Or download binary from GitHub releases:
# https://github.com/chipsalliance/verible/releases
# Example (replace VERSION):
# wget https://github.com/chipsalliance/verible/releases/download/v0.0-3752-g95f014d6/verible-v0.0-3752-g95f014d6-linux-static-x86_64.tar.gz
# tar xf verible-*.tar.gz && sudo mv verible-*/bin/* /usr/local/bin/
```

### Linux — Fedora / RHEL / CentOS

```bash
# Verilator
sudo dnf install verilator

# Verible — use GitHub releases (not in default repos)
# Download from: https://github.com/chipsalliance/verible/releases
# Extract and place binaries in /usr/local/bin/
```

### Verify install

```bash
verilator --version
verible-verilog-lint --version
```

### When to proactively offer installation

- User asks to lint or generate Verilog and tools are missing
- Suggest the install commands and offer to verify after install with `which`
