---
name: fsm-rtl-design
description: Design, implement, document, and verify hardware RTL finite state machines. Use for Verilog/SystemVerilog Moore or Mealy FSM RTL, state encoding choices, power/area/timing-aware FSM structure, RTL state diagrams in DOT or Mermaid, and WaveDrom waveform/timing generation from FSM behavior. Also trigger for requests combining FSM diagrams, RTL code, and waveforms.
---

# FSM RTL Design

## Core Workflow

1. Identify the target and constraints: ASIC or FPGA, vendor/tool if known, Verilog or SystemVerilog, reset style, clocking, latency, output timing, and whether illegal-state recovery is required.
2. Extract the FSM contract: states, reset state, inputs, outputs, transition guards, terminal/idle states, and any same-cycle output requirements.
3. Choose the machine type:
   - Prefer a Moore FSM or registered-Mealy FSM for production RTL.
   - Use a true combinational Mealy output only when the output must respond inside the current cycle.
4. Choose an RTL structure:
   - Separate state register, next-state logic, output logic, and output register when outputs leave the block or drive enables/handshakes.
   - Use nonblocking assignments in clocked blocks and blocking assignments in combinational blocks.
   - Give every combinational output a default before `case` statements.
5. Choose encoding based on target:
   - FPGA: start with tool `auto`, then sweep `one_hot`, `sequential`, and topology-specific `gray` or `johnson` if area/power/timing matters.
   - ASIC: start with minimum-bit sequential encoding; use custom transition-aware encoding only when activity data justifies it.
6. Produce only the requested artifacts: RTL, state diagram, waveform, verification notes, or a combined design package.

## Load References Only When Needed

- For power/area/timing tradeoffs, encoding strategy, decomposition, safe-state recovery, or RTL style rationale, read [references/design-guidance.md](references/design-guidance.md).
- For Graphviz DOT state diagrams, especially hardware/RTL documentation, read [references/diagrams-dot.md](references/diagrams-dot.md).
- For Mermaid `stateDiagram-v2`, GitHub/GitLab Markdown diagrams, or user-facing flow docs, read [references/diagrams-mermaid.md](references/diagrams-mermaid.md).
- For Moore Verilog RTL, read [references/verilog-moore.md](references/verilog-moore.md).
- For true Mealy or registered-Mealy Verilog RTL, read [references/verilog-mealy.md](references/verilog-mealy.md).
- For WaveDrom timing diagrams or signal waveforms, read [references/wavedrom-fsm.md](references/wavedrom-fsm.md).

Do not load DOT, Mermaid, WaveDrom, Moore, or Mealy examples unless the user asks for that artifact or the artifact is required to answer the task.

## Artifact Rules

- If the user asks for a hardware FSM diagram and does not specify a format, prefer DOT. Use Mermaid when the output must render in Markdown or the user asks for Mermaid.
- In DOT diagrams, label Moore outputs inside state nodes and Mealy outputs on transition labels.
- In Mermaid diagrams, use transition labels of the form `event [guard] / action`; keep hardware signal names exact and monospace-friendly.
- In WaveDrom diagrams, show `clk`, reset, driving inputs, a multi-bit `state` lane, and externally visible outputs. Group request/response or input/output signals when it improves readability.
- For RTL, preserve the user's requested language and reset polarity. If unspecified, use synthesizable Verilog-2001 with active-low asynchronous reset.
- For generated RTL, include a short note about latency: Moore and registered-Mealy outputs update on a clock edge; true Mealy outputs can change combinationally within a cycle.

## Verification Checklist

- Reset reaches exactly one legal state.
- Every state has a default hold or explicit transition.
- Every combinational block has complete defaults and no inferred latches.
- Illegal states recover if the design requires safe operation.
- Output timing matches the requested protocol latency.
- The waveform covers reset, nominal transition flow, stalls/holds, and at least one edge-case transition.
