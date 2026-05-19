# Graphviz DOT FSM Diagrams

Use DOT for RTL documentation when the user does not require Mermaid. DOT is compact, renders cleanly to SVG/PNG, and maps naturally to hardware-style state names and signal labels.

## Basic RTL FSM

```dot
digraph FSM {
    rankdir=LR;
    node [shape=circle fontname="monospace"];
    edge [fontname="monospace" fontsize=10];

    __start [shape=point width=0.2];
    __start -> IDLE;

    IDLE;
    FETCH;
    DECODE;
    EXECUTE;
    WRITEBACK;

    IDLE      -> FETCH     [label="start"];
    FETCH     -> DECODE    [label="mem_ready"];
    DECODE    -> EXECUTE   [label="decode_done"];
    EXECUTE   -> WRITEBACK [label="alu_done"];
    WRITEBACK -> IDLE      [label="done"];
    WRITEBACK -> FETCH     [label="!done / pc_inc"];
}
```

Render with:

```bash
dot -Tsvg fsm.dot -o fsm.svg
dot -Tpng fsm.dot -o fsm.png
```

## Moore Annotation

Put state-dependent outputs in the state node label.

```dot
digraph Moore {
    rankdir=LR;
    node [shape=circle fontname="monospace"];
    edge [fontname="monospace" fontsize=10];

    __start [shape=point width=0.2];
    __start -> IDLE;

    IDLE [label="IDLE\nbusy=0\ndone=0"];
    RUN  [label="RUN\nbusy=1\ndone=0"];
    DONE [label="DONE\nbusy=0\ndone=1"];

    IDLE -> RUN  [label="start"];
    RUN  -> DONE [label="ack"];
    RUN  -> RUN  [label="!ack"];
    DONE -> IDLE [label="1"];
}
```

## Mealy Annotation

Put input-dependent outputs on transition labels.

```dot
digraph Mealy {
    rankdir=LR;
    node [shape=circle fontname="monospace"];
    edge [fontname="monospace" fontsize=10];

    __start [shape=point width=0.2];
    __start -> IDLE;

    IDLE -> RUN  [label="start / req=1"];
    RUN  -> DONE [label="ack / done=1"];
    RUN  -> RUN  [label="!ack / done=0"];
    DONE -> IDLE [label="1 / req=0"];
}
```

## Conventions

- Use `rankdir=LR` for hardware flow diagrams.
- Use uppercase state names when matching RTL constants.
- Use `!sig`, `sig_a && sig_b`, and `count == N` style labels to match RTL.
- Add reset with a point node named `__start`.
- Use `doublecircle` only for accepting/final states, not normal idle states unless finality matters.
