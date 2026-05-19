# WaveDrom for RTL FSMs

Use WaveDrom when the user asks for a waveform, timing diagram, handshake timing, or a visual explanation of state/output latency.

## FSM Waveform Rules

- Include `clk` and reset.
- Show driving inputs before the `state` lane.
- Represent state as a multi-bit bus with `=` and state names in `data`.
- Show externally visible outputs after the `state` lane.
- Use one wave character per cycle unless the user specifies sub-cycle timing.
- For true Mealy outputs, show the output changing in the same cycle as the input.
- For Moore or registered-Mealy outputs, show outputs changing only on clock edges.

## Moore or Registered-Output Example

```json
{ "signal": [
  { "name": "clk",   "wave": "p........" },
  { "name": "rst_n", "wave": "01......." },
  {},
  ["inputs",
    { "name": "start", "wave": "0.10....." },
    { "name": "ack",   "wave": "0....10.." }
  ],
  {},
  ["fsm",
    { "name": "state", "wave": "x.=.=.=..", "data": ["IDLE", "RUN", "DONE"] },
    { "name": "busy",  "wave": "0..1..0.." },
    { "name": "done",  "wave": "0.....10." }
  ]
],
  "head": { "text": "Moore FSM timing", "tick": 0 },
  "config": { "hscale": 2 }
}
```

## True Mealy Same-Cycle Output Example

```json
{ "signal": [
  { "name": "clk",       "wave": "p......" },
  { "name": "rst_n",     "wave": "01....." },
  { "name": "in_a",      "wave": "0.10..." },
  { "name": "state",     "wave": "x.=.=..", "data": ["IDLE", "RUN"] },
  { "name": "out_pulse", "wave": "0.10..." }
],
  "head": { "text": "True Mealy same-cycle pulse", "tick": 0 },
  "config": { "hscale": 2 }
}
```

## Edge Annotation Example

```json
{ "signal": [
  { "name": "clk",   "wave": "p......" },
  { "name": "start", "wave": "0.10...", "node": "..a...." },
  { "name": "busy",  "wave": "0..1...", "node": "...b..." }
],
  "edge": ["a~>b registered latency"],
  "config": { "hscale": 2 }
}
```

## Rendering

If the user wants a file, check for `wavedrom-cli` and render:

```bash
wavedrom-cli -i fsm.json5 -s fsm.svg
wavedrom-cli -i fsm.json5 -p fsm.png
```
