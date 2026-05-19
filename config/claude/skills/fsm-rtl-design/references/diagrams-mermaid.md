# Mermaid FSM Diagrams

Use Mermaid `stateDiagram-v2` when the diagram must render directly in Markdown or the user asks for Mermaid.

## Basic RTL FSM

```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE

    IDLE --> FETCH : start
    FETCH --> DECODE : mem_ready
    DECODE --> EXECUTE : decode_done
    EXECUTE --> WRITEBACK : alu_done
    WRITEBACK --> IDLE : done
    WRITEBACK --> FETCH : !done / pc_inc
```

## Moore-Style Labels

For Moore machines, show state outputs in notes or state labels.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE

    state "IDLE\nbusy=0\ndone=0" as IDLE
    state "RUN\nbusy=1\ndone=0" as RUN
    state "DONE\nbusy=0\ndone=1" as DONE

    IDLE --> RUN : start
    RUN --> RUN : !ack
    RUN --> DONE : ack
    DONE --> IDLE : 1
```

## Mealy-Style Labels

For Mealy machines, put output actions on transitions.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE

    IDLE --> RUN : start / req=1
    RUN --> RUN : !ack / done=0
    RUN --> DONE : ack / done=1
    DONE --> IDLE : 1 / req=0
```

## Branching

```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE
    IDLE --> CHECK : start

    state CHECK <<choice>>
    CHECK --> READ : mode_read
    CHECK --> WRITE : mode_write
    CHECK --> ERROR : invalid_mode

    READ --> IDLE : read_done
    WRITE --> IDLE : write_done
    ERROR --> IDLE : clear
```

## Conventions

- Prefer `direction LR` for hardware control paths.
- Use exact RTL signal names in labels.
- Use `event [guard] / action` for combined conditions and side effects.
- Keep diagrams flat unless hierarchy is part of the actual architecture.
