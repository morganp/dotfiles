# RTL FSM Design Guidance

## Default Style

Use an explicit extracted FSM with:

- a registered state block,
- separate combinational next-state logic,
- registered outputs when outputs leave the block,
- Moore outputs unless a same-cycle response is required,
- blocking assignments in combinational logic,
- nonblocking assignments in sequential logic.

This style is easy for synthesis tools to recognize, avoids latch inference, and reduces glitch propagation into downstream logic.

## Moore vs Mealy

- **Moore**: outputs are determined by state. Prefer this when one-cycle output latency is acceptable and clean registered behavior matters.
- **True Mealy**: outputs are determined by state plus current inputs in combinational logic. Use only when same-cycle response is required.
- **Registered Mealy**: next output is computed from current state plus inputs and then registered. This preserves Mealy decision timing at the clock edge while producing glitch-free outputs.

For production RTL, choose Moore or registered-Mealy before true Mealy.

## Encoding Strategy

There is no universally best state encoding.

For **FPGA** targets:

- Start with the synthesis tool's `auto` encoding.
- Sweep `one_hot` and `sequential` for meaningful FSMs.
- Try `gray` or `johnson` for long, mostly linear paths with little branching.
- Expect one-hot to be competitive for speed on LUT fabrics, especially for medium or larger FSMs.
- Expect sequential/minimum-bit encoding to be competitive for small FSMs or register-limited designs.

For **ASIC** targets:

- Start with minimum-bit sequential encoding.
- If power is critical and transition probabilities are known, use custom transition-aware state assignment within the bit budget.
- Do not force one-hot unless timing or output-encoding benefits outweigh flip-flop area and clock power.

## Power and Area Notes

- Registered outputs reduce glitches and downstream switching.
- Transition-aware state assignment can reduce expected switching when realistic transition probabilities are known.
- FSM decomposition can reduce power for large clustered machines where only one sub-FSM is active most of the time.
- Safe-state recovery adds logic. Use it for safety or reliability requirements, not as a power/area optimization.

## Tool Attributes

Vivado examples:

```verilog
(* fsm_encoding = "auto" *) reg [1:0] state_q, state_d;
(* fsm_encoding = "one_hot" *) reg [3:0] state_q, state_d;
(* fsm_encoding = "sequential" *) reg [1:0] state_q, state_d;
```

Quartus examples:

```verilog
(* syn_encoding = "default" *) reg [1:0] state_q, state_d;
(* syn_encoding = "one-hot" *) reg [3:0] state_q, state_d;
(* syn_encoding = "sequential" *) reg [1:0] state_q, state_d;
```

Keep attributes close to the state register declaration. If the user wants portable RTL, omit vendor attributes and describe the intended synthesis setting separately.

## Review Questions

- Does the output need same-cycle response, or is one-cycle registered latency acceptable?
- Does the state graph have a dominant idle/hub state?
- Is the transition graph mostly linear, highly branched, or clustered?
- Are outputs mostly state indicators that could be folded into state encoding?
- Is illegal-state recovery required by the product or verification plan?
